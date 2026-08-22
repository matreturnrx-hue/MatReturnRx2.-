import type { Schema } from "../../data/resource";

/**
 * Handler for the `processAction` mutation.
 *
 * Identity comes from `event.identity`, which AppSync populates from the
 * verified Cognito JWT. It is never read from the arguments — that is the
 * whole point of moving off `POST /process-action`, where the client sent its
 * own `user_id` and fell back to the string "anonymous" when it had none.
 */

const MEDICAL_DISCLAIMER =
  "MatReturnRx provides educational performance and recovery guidance. It does " +
  "not diagnose, treat, or replace medical care. Stop and seek evaluation from " +
  "a qualified healthcare professional if symptoms worsen, new symptoms appear, " +
  "or red flags are present.";

/** Pain at or above this level is not something the app should plan around. */
const REFERRAL_PAIN_THRESHOLD = 5;

const ALLOWED_ACTIONS = new Set([
  "daily_training_plan",
  "recovery_score",
  "hydration_plan",
  "weight_cut_countdown",
  "skin_check",
  "mental_toughness",
  "neck_rehab",
  "shoulder_rehab",
  "knee_rehab",
  "mobility_plan",
  "return_to_sport",
]);

export const handler: Schema["processAction"]["functionHandler"] = async (
  event,
) => {
  const athleteId = event.identity && "sub" in event.identity
    ? event.identity.sub
    : undefined;

  if (!athleteId) {
    throw new Error("Unauthenticated request rejected.");
  }

  const { actionType, painLevel, symptoms, injuryLocation } = event.arguments;

  if (!ALLOWED_ACTIONS.has(actionType)) {
    throw new Error(`Unsupported action type: ${actionType}`);
  }

  // Safety gate runs before the model, not after. A high pain report is a
  // referral, not a prompt — the app must not generate training guidance for it
  // regardless of what the provider would return.
  if (typeof painLevel === "number" && painLevel >= REFERRAL_PAIN_THRESHOLD) {
    return {
      title: "Pause and Get Evaluated",
      summary:
        "You reported pain at a level MatReturnRx will not train through. " +
        "This is not a diagnosis — it means the app cannot determine whether " +
        "training is safe for you today.",
      recommendations: [
        "Do not train today.",
        "Seek evaluation from a qualified healthcare professional before returning to the mat.",
        "Note when the pain started, what makes it better or worse, and any new symptoms.",
      ],
      progressions: null,
      regressions: null,
      safetyFlags: ["Reported pain at or above the referral threshold."],
      nextStep: "Book an evaluation. Check back in once you have been cleared.",
      disclaimer: MEDICAL_DISCLAIMER,
    };
  }

  // ────────────────────────────────────────────────────────────────────────
  // BLOCKED — AI provider not yet determined.
  //
  // Nothing in the repository indicates which provider MatReturnRx uses. There
  // is no Bedrock reference in the Swift source, no provider SDK, and no
  // credential anywhere. Rather than invent an integration, this function
  // fails closed and the app shows its unavailable state.
  //
  // To finish this, pick one and replace the throw below:
  //
  //   Amazon Bedrock — add `bedrock:InvokeModel` to this function's role, then
  //     call BedrockRuntimeClient. No key to store; IAM handles auth.
  //
  //   External provider — store the key with `npx ampx sandbox secret set`,
  //     reference it via `secret('PROVIDER_API_KEY')` in resource.ts, and read
  //     it from process.env here. Never inline it.
  //
  // Whichever you choose, the response must be validated against the ActionPlan
  // shape and MEDICAL_DISCLAIMER must be attached before returning. Do not let
  // model output through unchecked — this is health-adjacent guidance for
  // athletes, some of them minors.
  // ────────────────────────────────────────────────────────────────────────

  console.info("processAction invoked", {
    athleteId,
    actionType,
    hasSymptoms: Boolean(symptoms),
    hasInjuryLocation: Boolean(injuryLocation),
  });

  throw new Error(
    "AI planning is not yet configured for this environment. " +
      "See amplify/functions/process-action/handler.ts.",
  );
};
