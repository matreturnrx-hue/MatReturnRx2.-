import { defineFunction } from "@aws-amplify/backend";

/**
 * AI action dispatch for MatReturnRx Pro.
 *
 * Exists so that no AI provider credential ever reaches the iOS client. The app
 * calls the `processAction` mutation with a Cognito token; this function holds
 * the provider secret and is the only thing that talks to the model.
 */
export const processAction = defineFunction({
  name: "process-action",
  entry: "./handler.ts",
  timeoutSeconds: 60,
  memoryMB: 512,
});
