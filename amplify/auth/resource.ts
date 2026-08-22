import { defineAuth } from "@aws-amplify/backend";

/**
 * MatReturnRx authentication — Amazon Cognito user pool.
 *
 * Replaces the Gen 2 starter's default (email-only, no attributes). The `name`
 * attribute is required because AuthManager reads it during session restore to
 * populate the athlete's display name; without it that lookup silently no-ops.
 *
 * Sign in with Apple is intentionally NOT declared here yet — see BLOCKED below.
 */
export const auth = defineAuth({
  loginWith: {
    email: true,

    // BLOCKED — Sign in with Apple.
    //
    // The iOS client currently hand-rolls a POST to the Cognito hosted domain
    // using grant_type=jwt-bearer, which Cognito does not support. The fix is
    // Amplify.Auth.signInWithWebUI(for: .apple), which requires this block:
    //
    //   externalProviders: {
    //     signInWithApple: {
    //       clientId: secret('SIWA_CLIENT_ID'),
    //       keyId: secret('SIWA_KEY_ID'),
    //       privateKey: secret('SIWA_PRIVATE_KEY'),
    //       teamId: secret('SIWA_TEAM_ID'),
    //     },
    //     callbackUrls: ['matreturnrx://callback'],
    //     logoutUrls: ['matreturnrx://signout'],
    //   }
    //
    // Those four values come from your Apple Developer account (Certificates,
    // Identifiers & Profiles -> Keys -> Sign in with Apple). They are secrets
    // and must be set with `npx ampx sandbox secret set`, never committed.
    // Uncomment and populate once you have them.
  },

  userAttributes: {
    // Written at sign-up from the athlete's full name.
    fullname: { required: true, mutable: true },
  },
});
