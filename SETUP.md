# Setup and Blocked Items

Everything MatReturnRx still needs before it can build, deploy, and run — with
where each value comes from and what breaks without it.

Nothing here is invented. Where a value is unknown it is marked **BLOCKED**
rather than filled with a plausible-looking placeholder.

---

## Priority order

| # | Item | Blocks | Who |
| --- | --- | --- | --- |
| 1 | [Commit the Swift sources](#1-commit-the-swift-sources) | Everything | You |
| 2 | [Verify the Xcode project opens](#2-verify-the-xcode-project-opens) | iOS build | You |
| 3 | [Deploy the backend](#3-deploy-the-backend) | Auth, all data | You (AWS) |
| 4 | [Sign in with Apple](#4-sign-in-with-apple) | Apple auth | Apple Developer |
| 5 | [AI provider](#5-ai-provider) | Pro AI plans | Decision + credential |
| 6 | [App Store Server API](#6-app-store-server-api) | Pro entitlement | App Store Connect |
| 7 | [StoreKit test config](#7-storekit-test-configuration) | Local purchase testing | You |
| 8 | [Branch protection](#8-branch-protection) | Nothing — hygiene | Repo admin |

---

## 1. Commit the Swift sources

**Status: BLOCKED — this is the largest blocker in the project.**

`MatReturnRx Dev/` does not exist in this repository. The Xcode project
references it via `PBXFileSystemSynchronizedRootGroup`, so the app target has an
empty `Sources` build phase and compiles to an empty application.

Commit the folder itself — not a zip of the `.xcodeproj`. Known to be missing:

```
MatReturnRx Dev/
├── MatReturnRx_DevApp.swift
├── ContentView.swift          ← the monolith: every screen + navigation
├── Item.swift                 ← Xcode SwiftData template file, likely unused
├── Assets.xcassets/
├── Core/                      AppTheme, CoreModels, ModuleData
├── Legal/                     LegalContent, LegalViews
└── Services/                  AmplifyService, AppState, AuthService,
                               ProgressService, SupabaseService
```

`Services/SupabaseService.swift` appears to have been repurposed to hold the
AWS-facing `Cloud*` types without being renamed. Confirm and rename to
`CloudProcessingService.swift`.

Until this lands, the `iOS · build` CI job skips and nothing about the app can
be verified.

---

## 2. Verify the Xcode project opens

**Status: needs a human with a Mac.**

The project was retargeted from macOS to iOS and `aws-amplify/amplify-swift`
was added by editing `project.pbxproj` directly. That file was validated by
parsing it — 44 objects, no dangling references — but no one has opened it in
Xcode.

Open `MatReturnRx Dev.xcodeproj` and confirm:

- [ ] It opens without a "damaged project file" error
- [ ] Package Dependencies lists `amplify-swift`, resolved
- [ ] The app target links `Amplify`, `AWSCognitoAuthPlugin`, `AWSAPIPlugin`
- [ ] Deployment target reads iOS 18.0, not macOS
- [ ] The scheme builds for an iOS Simulator destination

If it fails to open, say so — the pbxproj edit is revertible.

---

## 3. Deploy the backend

**Status: BLOCKED — no AWS credentials available to this session.**

The backend is defined but has never been deployed. There is no
`amplify_outputs.json` anywhere.

```bash
npm install
npx ampx sandbox        # personal dev stack
```

This creates the Cognito user pool, the AppSync API, the DynamoDB tables, and
both Lambda functions, then writes `amplify_outputs.json`.

**Then wire it into the app:**

1. Copy `amplify_outputs.json` into the app bundle (add to the Xcode target).
2. Confirm the app calls `Amplify.configure()` at startup.
3. Make configuration failure **loud**. The current code catches the error and
   only `print`s it, so the app runs in a permanently broken state while the UI
   shows a signed-in user restored from `UserDefaults`.

`amplify_outputs.json` is gitignored. It is per-environment and must not be
committed.

For production, connect the repo in Amplify Hosting and let
`ampx pipeline-deploy` run per branch.

### What to record once deployed

| Value | Where to find it |
| --- | --- |
| User pool ID | `amplify_outputs.json` → `auth.user_pool_id` |
| App client ID | `amplify_outputs.json` → `auth.user_pool_client_id` |
| AppSync endpoint | `amplify_outputs.json` → `data.url` |
| Region | `amplify_outputs.json` → `auth.aws_region` |

The old code hardcoded `https://matreturnrx.auth.us-east-1.amazoncognito.com`
and the literal string `REPLACE_WITH_APP_CLIENT_ID`. Neither should survive the
migration — configuration belongs in `amplify_outputs.json`, not in Swift.

---

## 4. Sign in with Apple

**Status: BLOCKED — four Apple Developer values needed.**

The current implementation cannot work. It POSTs to the Cognito hosted domain
with `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer`, which Cognito
does not support, then discards the tokens it gets back and marks the session
authenticated locally anyway.

The fix is `Amplify.Auth.signInWithWebUI(for: .apple)`, which needs the provider
configured in `amplify/auth/resource.ts`.

**From Apple Developer → Certificates, Identifiers & Profiles → Keys**, create a
Sign in with Apple key and collect:

| Value | Where |
| --- | --- |
| `SIWA_CLIENT_ID` | Your Services ID (not the bundle ID) |
| `SIWA_TEAM_ID` | Membership → Team ID |
| `SIWA_KEY_ID` | The key's 10-character ID |
| `SIWA_PRIVATE_KEY` | The downloaded `.p8` contents |

Store them as secrets — never commit the `.p8`:

```bash
npx ampx sandbox secret set SIWA_CLIENT_ID
npx ampx sandbox secret set SIWA_TEAM_ID
npx ampx sandbox secret set SIWA_KEY_ID
npx ampx sandbox secret set SIWA_PRIVATE_KEY
```

Then uncomment the `externalProviders` block in `amplify/auth/resource.ts` and
pick callback/logout URL schemes for the app.

---

## 5. AI provider

**Status: BLOCKED — the provider has not been decided.**

Nothing in the codebase indicates which provider MatReturnRx uses. There is no
Bedrock reference in the Swift source, no provider SDK, and no credential
anywhere. `amplify/functions/process-action/handler.ts` therefore fails closed.

Pick one:

### Option A — Amazon Bedrock

No key to store; the function's IAM role handles authentication.

1. Request model access in the Bedrock console for your region.
2. Grant `bedrock:InvokeModel` to the function role in `amplify/backend.ts`.
3. Call `BedrockRuntimeClient` from the handler.

### Option B — external provider

1. `npx ampx sandbox secret set PROVIDER_API_KEY`
2. Reference it via `secret('PROVIDER_API_KEY')` in the function's
   `resource.ts`.
3. Read it from `process.env` in the handler. Never inline it.

**Either way**, two rules hold:

- Validate the response against the `ActionPlan` shape before returning it.
  Do not let model output through unchecked.
- `MEDICAL_DISCLAIMER` must be attached to every response.

The pain-based referral gate already runs before any provider call and must stay
that way. This is health-adjacent guidance for athletes, some of them minors.

---

## 6. App Store Server API

**Status: BLOCKED — credentials not available.**

`verify-purchase` cannot verify a StoreKit transaction without them, so
`Entitlement` is never written and nothing can grant Pro.

**From App Store Connect → Users and Access → Integrations → App Store Connect
API**, create a key and collect:

| Value | Notes |
| --- | --- |
| Issuer ID | UUID, shown above the key list |
| Key ID | 10 characters |
| Private key | `.p8` file — **secret**, store with `ampx sandbox secret set` |
| Bundle ID | Must match the app; currently `MatReturnRx--LLC..MatReturnRx-Dev` |

Note the bundle ID contains a double dot and a `Dev` suffix. Decide the
production identifier before submitting.

**Also worth wiring:** App Store Server Notifications V2 pointed at a second
function, so refunds and cancellations revoke Pro without waiting for the app to
next open. Without it, revocation only takes effect on next launch.

---

## 7. StoreKit test configuration

**Status: missing.**

There is no `.storekit` file in the project, so the purchase flow cannot be
tested locally.

1. In Xcode: File → New → File → StoreKit Configuration File.
2. Add `pro_6_month_1499` (6-month, $14.99/mo) and `pro_12_month_1099`
   (12-month, $10.99/mo).
3. Select it in the scheme's Run → Options → StoreKit Configuration.

**Also confirm** both products exist and are approved in App Store Connect.
`Product.products(for:)` returns an empty array for products that do not exist,
and the app currently surfaces that as "not available right now."

---

## 8. Branch protection

**Status: needs a repo admin. Not doable via the GitHub App — it lacks the
`administration` permission.**

PR #3 was merged while its CI was still running, which put a failing workflow on
`main`. Requiring the check prevents a repeat.

**Settings → Rules → Rulesets → New branch ruleset**

- Target `main` (Add target → Include default branch)
- Enable **Require status checks to pass** → add **`Backend · typecheck`**
- Enable **Require a pull request before merging**

Do not require `iOS · build` yet. It currently passes by skipping, so requiring
it enforces nothing — and it will start blocking legitimately the moment real
sources land and the first build fails.

---

## Known-good state

As of the last verified run on `main`:

- `npm install` → succeeds, 901 packages
- `npx tsc --noEmit` → exits 0
- schema constructs under `tsx` → `schema ok`
- `project.pbxproj` → parses, 44 objects, no dangling references
- CI on `main` → both jobs green

Not verified anywhere: that Xcode opens the project, that the app builds, that
the backend deploys.
