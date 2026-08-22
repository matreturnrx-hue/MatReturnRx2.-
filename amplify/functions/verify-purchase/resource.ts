import { defineFunction } from "@aws-amplify/backend";

/**
 * Server-side StoreKit verification.
 *
 * The Entitlement model is not writable by the client, so this is the only path
 * that can grant Pro. It exists because the app currently treats
 * `UserDefaults["mrx_pro"]` as proof of entitlement — a value any device can
 * edit, and one the app never revokes.
 */
export const verifyPurchase = defineFunction({
  name: "verify-purchase",
  entry: "./handler.ts",
  timeoutSeconds: 30,
  memoryMB: 256,
});
