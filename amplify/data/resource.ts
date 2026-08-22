import { type ClientSchema, a, defineData } from "@aws-amplify/backend";
import { processAction } from "../functions/process-action/resource.js";
import { verifyPurchase } from "../functions/verify-purchase/resource.js";

/**
 * MatReturnRx data layer.
 *
 * Replaces the Amplify Gen 2 starter's `Todo` model, which was authorized with
 * `allow.publicApiKey()` and a 30-day key — meaning every record was readable
 * and writable by anyone holding the key, with no user identity involved.
 *
 * Two rules govern everything below:
 *
 *  1. `allow.owner()` is the ONLY read/write path for athlete data. AppSync
 *     resolves the owner from the verified Cognito JWT, so the client cannot
 *     name someone else's ID to reach their records. This is what closes the
 *     IDOR exposure flagged as S2 in the audit — the old REST design took the
 *     user ID from the URL path (`/progress/{userId}`) and trusted it.
 *
 *  2. Entitlement is never client-writable. The app may read it; only the
 *     verify-purchase function may write it. A device that edits its local
 *     state cannot grant itself Pro.
 */
const schema = a
  .schema({
    // ── Enums ────────────────────────────────────────────────────────────

    TrafficLight: a.enum(["green", "yellow", "red"]),

    SubscriptionTier: a.enum(["free", "pro"]),

    // ── Athlete profile ──────────────────────────────────────────────────
    //
    // Note what is absent: isPro, subscriptionTier, subscriptionStatus. The
    // old AthleteProfile carried all three, which is how a backend response of
    // `is_pro: false` could still flip the app into Pro. Entitlement lives in
    // its own model with its own authorization.

    UserProfile: a
      .model({
        fullName: a.string(),
        sport: a.string(),
        experienceLevel: a.string(),
        trainingPhase: a.string(),
        heightCm: a.float(),
        weightKg: a.float(),
        competitionWeightKg: a.float(),
        goals: a.string().array(),
        selectedBodyAreas: a.string().array(),
        availableEquipment: a.string().array(),
        isMinor: a.boolean(),
        hasCompletedOnboarding: a.boolean(),
      })
      .authorization((allow) => [allow.owner()]),

    // ── Readiness check-ins ──────────────────────────────────────────────
    //
    // `entryDate` is stored explicitly rather than relying on createdAt so the
    // Progress tab's Week / Month / 3-Month filters query a field the athlete's
    // timezone actually agrees with.

    ReadinessEntry: a
      .model({
        entryDate: a.datetime().required(),
        readinessScore: a.float().required(),
        trafficLight: a.ref("TrafficLight").required(),
        sleepQuality: a.float(),
        sorenessLevel: a.float(),
        stressLevel: a.float(),
        painLevel: a.float(),
        motivation: a.float(),
        confidence: a.float(),
      })
      .authorization((allow) => [allow.owner()]),

    // ── Completed training sessions ──────────────────────────────────────
    //
    // Separate from ReadinessEntry on purpose. The old ProgressService stored
    // both in one array and then counted the whole array as "sessions", so a
    // week of check-ins with no training still reported seven sessions.

    SessionEntry: a
      .model({
        entryDate: a.datetime().required(),
        moduleId: a.string().required(),
        moduleName: a.string().required(),
        painLevel: a.float(),
        durationMin: a.integer(),
        completed: a.boolean().required(),
        feltAfter: a.string(),
      })
      .authorization((allow) => [allow.owner()]),

    // ── Legal acceptance records ─────────────────────────────────────────
    //
    // Create and read only — no update, no delete. A consent record that can be
    // edited after the fact is not a consent record. These currently live only
    // in device UserDefaults under the placeholder user ID "pending", so no
    // durable attributable record exists today (audit §4.12).

    LegalAcceptance: a
      .model({
        documentKey: a.string().required(),
        documentTitle: a.string().required(),
        documentVersion: a.string().required(),
        acceptedAt: a.datetime().required(),
        userRole: a.string().required(),
        appVersion: a.string().required(),
        deviceId: a.string(),
        parentGuardianName: a.string(),
        parentGuardianEmail: a.string(),
      })
      .authorization((allow) => [allow.owner().to(["create", "read"])]),

    // ── Entitlement ──────────────────────────────────────────────────────
    //
    // The athlete may read their own entitlement. Only verify-purchase writes
    // it, after validating the transaction against Apple. StoreKit remains the
    // source of truth on-device; this model exists so entitlement survives a
    // reinstall and can be checked server-side before Pro content is returned.

    Entitlement: a
      .model({
        tier: a.ref("SubscriptionTier").required(),
        productId: a.string(),
        originalTransactionId: a.string(),
        expiresAt: a.datetime(),
        revokedAt: a.datetime(),
        lastVerifiedAt: a.datetime().required(),
      })
      // Read-only for the athlete. Write access belongs to verify-purchase,
      // granted at schema level below — `allow.resource` is schema-scoped in
      // Amplify Gen 2 and is not available on an individual model.
      .authorization((allow) => [allow.owner().to(["read"])]),

    // ── AI response shape ────────────────────────────────────────────────
    //
    // Mirrors the existing Swift `CloudResponse` so the client model does not
    // need to change shape. Declaring it here means AppSync validates the
    // Lambda's output instead of the app decoding whatever arrives.

    ActionPlan: a.customType({
      title: a.string().required(),
      summary: a.string().required(),
      recommendations: a.string().array().required(),
      progressions: a.string().array(),
      regressions: a.string().array(),
      safetyFlags: a.string().array(),
      nextStep: a.string().required(),
      disclaimer: a.string().required(),
    }),

    // ── AI action dispatch ───────────────────────────────────────────────
    //
    // Replaces POST /process-action. Note there is no userId argument: the
    // function reads the caller's identity from the AppSync event context, so
    // the client cannot claim to be another athlete — and cannot fall back to
    // the literal string "anonymous" the way CloudProcessingService does today.

    processAction: a
      .mutation()
      .arguments({
        actionType: a.string().required(),
        painLevel: a.integer(),
        symptoms: a.string(),
        injuryLocation: a.string(),
      })
      .returns(a.ref("ActionPlan"))
      .authorization((allow) => [allow.authenticated()])
      .handler(a.handler.function(processAction)),

    // ── Purchase verification ────────────────────────────────────────────

    verifyPurchase: a
      .mutation()
      .arguments({
        signedTransaction: a.string().required(),
      })
      .returns(a.ref("SubscriptionTier"))
      .authorization((allow) => [allow.authenticated()])
      .handler(a.handler.function(verifyPurchase)),
  })
  .authorization((allow) => [
    allow.resource(processAction).to(["query"]),
    allow.resource(verifyPurchase).to(["query", "mutate"]),
  ]);

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    // Every request must carry a verified Cognito token. The starter shipped
    // with `apiKey` as the default; nothing here is reachable without a user.
    defaultAuthorizationMode: "userPool",
  },
});
