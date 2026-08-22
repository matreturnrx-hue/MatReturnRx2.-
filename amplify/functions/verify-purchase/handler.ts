import type { Schema } from "../../data/resource";

/**
 * Handler for the `verifyPurchase` mutation.
 *
 * Takes the JWS-signed transaction StoreKit 2 hands the app, verifies it
 * against Apple, and writes the resulting Entitlement row. The client's opinion
 * about its own subscription is never trusted — it only supplies the signed
 * payload, which it cannot forge.
 */

export const handler: Schema["verifyPurchase"]["functionHandler"] = async (
  event,
) => {
  const athleteId = event.identity && "sub" in event.identity
    ? event.identity.sub
    : undefined;

  if (!athleteId) {
    throw new Error("Unauthenticated request rejected.");
  }

  const { signedTransaction } = event.arguments;

  if (!signedTransaction || signedTransaction.split(".").length !== 3) {
    throw new Error("Malformed signed transaction.");
  }

  // ────────────────────────────────────────────────────────────────────────
  // BLOCKED — App Store Server API credentials not available.
  //
  // Verifying a StoreKit 2 transaction requires four values from App Store
  // Connect (Users and Access -> Integrations -> App Store Connect API):
  //
  //   issuer ID, key ID, the .p8 private key, and the app's bundle ID
  //
  // None of them are in this repository, and I am not going to invent them.
  // Store the .p8 with `npx ampx sandbox secret set` and reference it from
  // resource.ts; the other three are configuration, not secrets.
  //
  // The implementation is then:
  //
  //   1. Verify the JWS signature chain against Apple's root CAs. Reject on
  //      any failure — an unverified transaction is not a purchase.
  //   2. Confirm the payload's bundleId matches this app.
  //   3. Confirm productId is pro_6_month_1499 or pro_12_month_1099.
  //   4. Read expiresDate and revocationDate from the payload.
  //   5. Upsert Entitlement for this athleteId:
  //        tier = (not revoked && expiresDate > now) ? 'pro' : 'free'
  //      Write 'free' on expiry and revocation too — the current client only
  //      ever grants Pro and has no downgrade path at all, which is the actual
  //      defect this function exists to fix.
  //   6. Return the resulting tier.
  //
  // Also worth wiring once the above works: App Store Server Notifications V2
  // pointed at a second function, so refunds and cancellations revoke Pro
  // without waiting for the app to next open.
  // ────────────────────────────────────────────────────────────────────────

  console.info("verifyPurchase invoked", { athleteId });

  throw new Error(
    "Purchase verification is not yet configured for this environment. " +
      "See amplify/functions/verify-purchase/handler.ts.",
  );
};
