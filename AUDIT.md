# MatReturnRx — Phase 1 Technical Audit

**Scope:** `matreturnrx-hue/MatReturnRx2.-` (primary), with corroborating evidence from `matreturnrx-hue/MatReturnRx`
**Date:** 2026-08-22
**Phase:** 1 — Audit only. **No code was modified.**

---

## 0. READ THIS FIRST — What Was Actually Available to Audit

This is the most important finding in the report, and it changes what every other section can honestly claim.

### 0.1 The repository under audit contains no Swift source code

`matreturnrx-hue/MatReturnRx2.-` contains exactly two files:

| File | Contents |
|---|---|
| `README.md` | The single line `# 2.0` |
| `MatReturnRx Dev.xcodeproj.zip` | The `.xcodeproj` **bundle only** |

The archive holds `project.pbxproj`, workspace metadata, and Xcode user state. It does **not** contain the `MatReturnRx Dev/` source folder. The full history of the repository (3 commits) has never contained a `.swift` file.

`project.pbxproj` declares its source folders through `PBXFileSystemSynchronizedRootGroup`:

```
9CD303FA… /* MatReturnRx Dev */      path = "MatReturnRx Dev";
9CD3040A… /* MatReturnRx DevTests */ path = "MatReturnRx DevTests";
9CD30414… /* MatReturnRx DevUITests */ path = "MatReturnRx DevUITests";
```

None of those directories exist in the archive. **Opening this project in Xcode produces three targets with zero source files and an empty `Sources` build phase.** It would "build successfully" only in the sense that it produces an empty application.

### 0.2 Where the real source was found

`README.md` in the sibling repository `matreturnrx-hue/MatReturnRx` contains **3,086 lines of MatReturnRx Swift source pasted as raw text**. This is the only real code available anywhere in the account, and it is the basis for Sections 3–8.

Files reconstructed from that paste (~2,100 lines of code + ~1,000 lines of embedded legal prose):

| File | Lines in dump | Contents |
|---|---|---|
| `Core/AppTheme.swift` | 1–52 | `extension Color` brand palette, `enum AppTheme` |
| `Core/CoreModels.swift` | 53–175 | `struct D` (legal constants), `TrafficLight`, `TLResult`, `MRXExercise`, `MRXModule`, `FeltResponse`, `evaluateReadiness()` |
| `Core/ModuleData.swift` | 176–358 | `let mrxModules: [MRXModule]` — 8 modules, 40 exercises |
| `Legal/LegalContent.swift` | 359–1341 | `LegalAcceptanceRecord`, `LegalDocument`, `LegalStore`, `LegalDocuments`, 5 full legal documents, `LegalParagraph` |
| `Legal/LegalViews.swift` | 1342–1815 | `LegalTextRenderer`, `LegalDocumentViewer`, `LegalCheckRow`, `LegalAcceptanceScreen`, `LegalStatusView` |
| `Services/AmplifyService.swift` | 1816–2123 | `configureAmplify()`, `AmplifyConfig`, `AmplifyAPIManager` — **pasted twice, byte-identical** |
| `Services/AppState.swift` | 2124–2411 | `SubscriptionManager` (StoreKit 2), `AppState` |
| `Services/AuthService.swift` | 2412–2712 | `AuthError`, `TokenManager`, `AuthManager`, nonce helpers |
| `Services/ProgressService.swift` | 2713–2877 | `ProgressEntry`, `ProgressService` |
| *(header missing — the file at `Services/SupabaseService.swift`)* | 2878–3086 | `CloudActionType`, `CloudRequest`, `CloudResponse`, `AthleteProfile`, `CloudProcessingError`, `CloudProcessingService` |

### 0.3 Files known to exist but never supplied

Xcode's `UserInterfaceState.xcuserstate` (recent-files records, from both repos) names these paths on the developer's machine:

- `MatReturnRx Dev/ContentView.swift` — **not supplied**
- `MatReturnRx Dev/MatReturnRx_DevApp.swift` — **not supplied**
- `MatReturnRx Dev/Item.swift` — **not supplied**
- `MatReturnRx Dev/Assets.xcassets` — **not supplied**

`ContentView.swift` is almost certainly the monolithic file referenced in the brief. It contains every screen (Home, Onboarding, Auth, Modules, Exercise, Progress, Profile, Paywall, Settings), the entire navigation graph, and the shared components `MRXField`, `MRXDisclaimerBox`, and `MRXButton` that `LegalViews.swift` references but that are defined nowhere in the supplied code.

### 0.4 Direct consequence for this audit

**I could not build, run, or test anything.** No Swift toolchain, no Xcode, no iOS SDK, no complete source tree. Every finding below is from static reading of source and project configuration. Nothing in this report is claimed as "verified by build" or "verified at runtime," because nothing was.

Specifically, the following items from the brief **cannot be assessed** with what was uploaded:

- `Double.random(in: 4...9)` — **this does not appear anywhere in the supplied code.** It lives in a file that was not provided (almost certainly `ContentView.swift`).
- The Progress tab's Week / Month / 3-Month selectors — the *service layer* behind them is correct (§4.7); the *view* that drives them was not supplied.
- Navigation, dead screens, screen reachability — `ContentView.swift` was not supplied.
- Memory leaks, retain cycles in views, body recomputation in screens — not supplied.

---

## SECTION 1 — Current Project Architecture

### 1.1 Targets and build configuration

Three targets, all created with Xcode 26.5, `objectVersion = 77`:

- `MatReturnRx Dev` (application) — bundle ID `MatReturnRx--LLC..MatReturnRx-Dev`
- `MatReturnRx DevTests` (unit tests)
- `MatReturnRx DevUITests` (UI tests)

Notable build settings:

| Setting | Value | Note |
|---|---|---|
| `SDKROOT` | `macosx` | **See §3, B3** |
| `MACOSX_DEPLOYMENT_TARGET` | `26.3` | macOS, not iOS |
| `COMBINE_HIDPI_IMAGES` | `YES` | macOS-only setting |
| `ENABLE_APP_SANDBOX` | `YES` | macOS App Sandbox |
| `LD_RUNPATH_SEARCH_PATHS` | `@executable_path/../Frameworks` | macOS bundle layout (iOS uses `@executable_path/Frameworks`) |
| `SWIFT_VERSION` | `5.0` | Swift 5 language mode |
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | `MainActor` | Types default to `@MainActor` |
| `SWIFT_APPROACHABLE_CONCURRENCY` | `YES` | Swift 6 migration aid |
| `LOCALIZATION_PREFERS_STRING_CATALOGS` | `YES` | Set, but unused — see §8.6 |
| `packageProductDependencies` | `()` on all 3 targets | **No SPM dependencies — see §3, B2** |

The last run destination recorded in Xcode's state was `dvtdevice-local-computer:localhost` / `arm64` / `macosx26.5` / `Mac15,13` — i.e. the developer has been building this as a Mac app.

### 1.2 Layer inventory

**Models** — `MRXModule`, `MRXExercise`, `TrafficLight`, `TLResult`, `FeltResponse`, `ProgressEntry`, `AthleteProfile`, `CloudRequest`, `CloudResponse`, `CloudErrorResponse`, `LegalDocument`, `LegalAcceptanceRecord`, `LegalParagraph`, `CloudActionType`, `AuthError`, `CloudProcessingError`.

**ViewModels** — none. There is no ViewModel layer. `AppState` is a single god-object `ObservableObject` holding 14 `@Published` properties spanning auth, profile, onboarding, entitlement, readiness, and paywall presentation.

**Services / managers** — six, five of them singletons:

| Type | Singleton | Role |
|---|---|---|
| `AuthManager` | `.shared` | Cognito sign-up / sign-in / Apple / reset / sign-out / session restore |
| `TokenManager` | `.shared` | Caches user ID + role in `UserDefaults` |
| `AmplifyAPIManager` | `.shared` | All REST calls |
| `ProgressService` | `.shared` | Readiness + session history |
| `LegalStore` | `.shared` | Legal acceptance records |
| `SubscriptionManager` | `.shared` | StoreKit 2 |
| `CloudProcessingService` | — | Stateless AI request builder |

`AppState` is *not* a singleton — it is passed as an explicit parameter into nearly every service method (`signIn(…, appState:)`, `addReadinessEntry(…, appState:)`, `purchase6Month(appState:)`, …), and the services mutate it directly. See §8.3.

**Screens (from supplied code)** — `LegalDocumentViewer`, `LegalAcceptanceScreen`, `LegalStatusView`, plus `LegalTextRenderer` / `LegalCheckRow` components. All other screens are in the unsupplied `ContentView.swift`.

**Content** — 8 modules / 40 exercises, hardcoded in `ModuleData.swift`. The Basic/Pro split matches the brief exactly:

- Basic (`isPro: false`): Mobility / Recovery, Knee Starter, Neck Starter, Shoulder Starter, Hip & Groin Injury Prevention, Lower Back Injury Prevention
- Pro (`isPro: true`): Grappling Strength Foundation, Return to Mat Protocol

Terminology is correct — "Injury Prevention," not "rehabilitation." Every module carries an `evidencePanel` string, and every exercise carries a `safetyWarning`. The `Return to Mat Protocol` panel explicitly states it does not provide medical clearance. **This content layer is in good shape and needs no repair.**

---

## SECTION 2 — AWS Architecture Map (Actual)

### 2.1 What the iOS client is written against

```
MatReturnRx app  (SwiftUI)
      |
      |  import Amplify / AWSCognitoAuthPlugin / AWSAPIPlugin
      |  >>> NOT LINKED — no SPM dependency declared <<<
      v
Amazon Cognito User Pool                          [ CONFIG ABSENT ]
  · Amplify.Auth.signUp / signIn / resetPassword / fetchAuthSession / signOut
  · hosted domain, hardcoded:
      https://matreturnrx.auth.us-east-1.amazoncognito.com   (unverified)
  · app client ID:  "REPLACE_WITH_APP_CLIENT_ID"             [ PLACEHOLDER ]
      |
      v
Amplify API — REST, apiName "matreturnrxAPI"      [ amplifyconfiguration.json ABSENT ]
  POST /process-action        -> AI action dispatch
  GET  /profiles/{userId}     -> athlete profile
  POST /profiles              -> upsert profile
  GET  /progress/{userId}     -> progress history
  POST /progress              -> append progress entry
      |
      v
API Gateway -> Lambda                             [ NOT IN REPO — UNVERIFIABLE ]
      |
      v
Database                                          [ UNKNOWN — no schema anywhere ]
Storage (S3)                                      [ ABSENT — zero S3 references in code ]
AI provider                                       [ UNKNOWN — no Bedrock reference in code ]
```

**Layer status:**

| Layer | Status |
|---|---|
| Auth | Code written, **not linked, not configured** |
| API | Code written, **not linked, not configured** |
| Backend logic | **Missing from repo** |
| Database | **Unknown** |
| Storage | **Not used** — exercise content is code-resident, no media pipeline |
| AI | **Endpoint contract defined, implementation absent** |

### 2.2 What actually exists as an AWS backend definition

The sibling repo contains `amplify-next-template-main/` — an **entirely unmodified AWS Amplify Gen 2 Next.js starter**:

```ts
// amplify/auth/resource.ts
export const auth = defineAuth({ loginWith: { email: true } });

// amplify/data/resource.ts
const schema = a.schema({
  Todo: a.model({ content: a.string() })
        .authorization((allow) => [allow.publicApiKey()]),
});
export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: "apiKey",
    apiKeyAuthorizationMode: { expiresInDays: 30 },
  },
});
```

The frontend is still the tutorial's todo list (`app/page.tsx`: `"My todos"`, `"🥳 App successfully hosted"`).

### 2.3 The central architectural conflict

**The only AWS backend definition that exists is Amplify Gen 2. The iOS client is written for Amplify Gen 1. They cannot talk to each other as written.**

| | iOS client | Amplify template |
|---|---|---|
| Generation | Gen 1 | Gen 2 |
| Config file | `amplifyconfiguration.json` | `amplify_outputs.json` |
| API style | REST (`RESTRequest`, `Amplify.API.post`) | GraphQL / AppSync (`generateClient<Schema>`) |
| Data models | `AthleteProfile`, `ProgressEntry` | `Todo` |
| Data store | API Gateway → Lambda → ? | AppSync → DynamoDB |
| Auth mode | Cognito user pool (implied) | **Public API key** |

There is **no** MatReturnRx data model deployed anywhere: no Profile, no Readiness, no WorkoutSession, no Program, no Entitlement. There is a `Todo`.

**This is not a "wire up the config" gap. The backend the app needs has not been built.**

---

## SECTION 3 — Build Problems

I could not compile. These are static findings, each with the reasoning that supports it.

| # | File / location | Problem | Cause | Fix | Severity |
|---|---|---|---|---|---|
| **B1** | `project.pbxproj` | App target has **zero source files**; `Sources` build phase is empty | The three `PBXFileSystemSynchronizedRootGroup` folders don't exist in the archive | Commit the actual source tree | **CRITICAL** |
| **B2** | All `Services/*.swift` | `import Amplify`, `import AWSCognitoAuthPlugin`, `import AWSAPIPlugin` → *No such module* | `packageProductDependencies = ()` on every target; `Frameworks` phases empty; `xcshareddata/swiftpm/configuration/` empty; **no `Package.resolved` anywhere** | Add `aws-amplify/amplify-swift` via SPM | **CRITICAL** |
| **B3** | `LegalContent.swift` (`LegalStore.accept`) | `UIDevice.current.identifierForVendor` → unresolved | `UIDevice` is UIKit/iOS-only; `SDKROOT = macosx` | Decide the target platform (§9, L1) | **CRITICAL** |
| **B4** | `LegalViews.swift` ×2 (`LegalDocumentViewer`, `LegalStatusView`) | `.navigationBarTitleDisplayMode(.inline)` → unavailable | iOS-only SwiftUI modifier under the macOS SDK | Same as B3 | **CRITICAL** |
| **B5** | `Services/AmplifyService.swift` | `configureAmplify()`, `enum AmplifyConfig`, `final class AmplifyAPIManager` each declared **twice, byte-identical** → *Invalid redeclaration* | Duplicated paste | Delete one copy | **CRITICAL** ¹ |
| **B6** | `LegalViews.swift` | `MRXField`, `MRXDisclaimerBox`, `MRXButton` used, defined nowhere in supplied code | Defined in unsupplied `ContentView.swift` | Supply the file | **HIGH** ² |
| **B7** | `CoreModels.swift` `evaluateReadiness` | `stress:` parameter never used → *unused parameter* warning | Traffic-light formula ignores stress entirely | See §4.10 | MEDIUM |
| **B8** | `AuthService.swift` | Local `enum AuthError` shadows `Amplify.AuthError` in the same file | Name collision | Rename to `MRXAuthError` | MEDIUM |
| **B9** | `AppState.swift` | `@MainActor class SubscriptionManager` with `deinit { transactionListenerTask?.cancel() }` | Nonisolated `deinit` touching actor-isolated state — warning in Swift 5 mode, **error under Swift 6** | Move cancellation out of `deinit` | MEDIUM |
| **B10** | 5 singletons | `AuthManager`, `TokenManager`, `ProgressService`, `LegalStore` are non-`Sendable` and crossed over `await` boundaries | Strict-concurrency diagnostics | Annotate `@MainActor` or make `Sendable` | MEDIUM |
| **B11** | `AppTheme.swift` | `Color.mrxCardLight` defined, never used | Dead | Delete | LOW |

¹ The duplication is definitely present in the source dump. Whether the **on-disk** file is duplicated must be confirmed against the real file — it is possible the paste, not the file, is doubled.
² Not a defect in itself — an artifact of the incomplete upload.

---

## SECTION 4 — Runtime Problems

### 4.1 Amplify configuration failure is swallowed — CRITICAL

```swift
func configureAmplify() {
    do {
        try Amplify.add(plugin: AWSCognitoAuthPlugin())
        try Amplify.add(plugin: AWSAPIPlugin())
        try Amplify.configure()
    } catch {
        print("[Amplify] Configuration failed: \(error)")   // <-- app continues
    }
}
```

With no `amplifyconfiguration.json` bundled, `Amplify.configure()` **throws on every launch**. The app prints and proceeds. Combined with `try?` on nearly every call site, the result is a perfectly quiet, permanently broken backend — while the UI happily shows a signed-in user restored from `UserDefaults`.

### 4.2 `fetchProfile` can never succeed — CRITICAL

```swift
private let decoder: JSONDecoder = {
    let d = JSONDecoder()
    d.keyDecodingStrategy = .convertFromSnakeCase   // rewrites "user_id" -> "userId"
    return d
}()
```

But `AthleteProfile` declares explicit snake_case keys:

```swift
enum CodingKeys: String, CodingKey {
    case userId = "user_id"
    …
}
```

`.convertFromSnakeCase` converts the *incoming* JSON key `user_id` to `userId` **before** matching, and the explicit `CodingKeys` still expect the literal `"user_id"`. They never match. `userId` is non-optional, so decoding throws `keyNotFound` — and the call site swallows it:

```swift
guard let data = try? await Amplify.API.get(request: restRequest) else { return nil }
return try? decoder.decode(AthleteProfile.self, from: data)   // always nil
```

**Consequence:** `loadAndHydrateProfile` never hydrates. Profile, sport, experience level, training phase, and backend `is_pro` are silently discarded on every sign-in and every session restore — even against a perfectly healthy backend.

Note the asymmetry: `upsertProfile` uses an encoder with `.useDefaultKeys`, so writes go out correctly in snake_case. **The app writes profiles it can never read back.**

### 4.3 Sign In with Apple cannot work — CRITICAL

```swift
URLQueryItem(name: "grant_type", value: "urn:ietf:params:oauth:grant-type:jwt-bearer"),
URLQueryItem(name: "client_id",  value: AmplifyConfig.appClientId),   // "REPLACE_WITH_APP_CLIENT_ID"
```

Three independent failures:

1. **Cognito's `/oauth2/token` does not support the `jwt-bearer` grant type.** It accepts `authorization_code`, `refresh_token`, and `client_credentials`. This request returns `400 unsupported_grant_type` regardless of everything else.
2. `client_id` is the literal placeholder string.
3. Even on a hypothetical success, **the returned tokens are decoded, read for a `sub` claim, and then thrown away.** They are never handed to Amplify. `Amplify.Auth.fetchAuthSession()` would still report *not signed in*, so every subsequent API call is unauthenticated and the next launch signs the user out.

And the failure mode is worse than a plain error:

```swift
let userId = jwtSubject(from: tokens.id_token ?? tokens.access_token) ?? UUID().uuidString
…
appState.register(name: name)      // sets isAuthenticated = true, writes "mrx_auth" = true
```

On a parse failure the app **fabricates a random UUID as the user's identity** and marks the session authenticated locally. Data then writes under a throwaway ID that changes every launch.

The correct approach is `Amplify.Auth.signInWithWebUI(for: .apple, …)`, which performs the authorization-code exchange and installs the session in Amplify's Keychain-backed store.

### 4.4 Nonce generation ignores its failure path — HIGH

```swift
var bytes = [UInt8](repeating: 0, count: length)
_ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)   // status discarded
```

If `SecRandomCopyBytes` fails, `bytes` stays all zeros and the function returns a **fully predictable nonce** with no signal. Two further defects: the raw nonce is sent to the token endpoint rather than the SHA-256 digest that `sha256Nonce` computes (that helper is defined but unused in this path), and the character set `"…UVXYZ…"` omits `W`.

### 4.5 `hydrateFromProfile` grants Pro when the backend says `false` — CRITICAL

```swift
if let pro = profile.isPro { activatePro(); _ = pro }
```

`activatePro()` is called whenever the field is **present**, regardless of value. A backend response of `"is_pro": false` grants Pro and writes `mrx_pro = true` to `UserDefaults`, where it persists across launches. The `_ = pro` discard suggests this was a compiler-warning silencer that replaced the actual conditional.

Correct form: `if profile.isPro == true { activatePro() } else { deactivatePro() }` — though entitlement should not come from the profile at all (§4.6).

### 4.6 Pro entitlement has three competing sources of truth — CRITICAL

| Source | Authority | Reality |
|---|---|---|
| `UserDefaults["mrx_pro"]` | none | Read as truth at launch in `AppState.load()` |
| `AthleteProfile.is_pro` | backend, unverified | Grants Pro even when `false` (§4.5) |
| `Transaction.currentEntitlements` | **the only real one** | Consulted, but **only ever grants** |

```swift
func refreshEntitlements(appState: AppState) async {
    if await hasActiveEntitlement() { appState.activatePro() }
    // no else — never revokes
}
```

`deactivatePro()` exists and is called from exactly one place: `signOut()`. So an expired, refunded, or revoked subscription **never downgrades the user**. And the transaction listener never touches entitlement state either:

```swift
for await result in Transaction.updates {
    if case .verified(let transaction) = result {
        await transaction.finish()          // finishes it, updates nothing
    }
}
```

Net effect: once Pro is granted by any path, it is permanent until sign-out. `UserDefaults` is the de-facto source of truth for a paid feature gate.

### 4.7 Progress data is device-local and leaks across accounts — HIGH

`ProgressService` stores the entire history as JSON in `UserDefaults["mrx_progress_entries_v2"]`. The cloud is best-effort only:

```swift
private func commit(_ entry: ProgressEntry, updating appState: AppState) {
    entries.append(entry)
    persist()
    …
    Task { try? await AmplifyAPIManager.shared.syncProgress(entry) }   // fire and forget
}
```

`syncProgress` itself is `_ = try? await …` internally, so **failures are swallowed twice**. There is no retry, no outbox, no dirty flag. Delete the app and every check-in, session, and streak is gone.

Worse, entries are **not namespaced by user, and `AppState.signOut()` does not clear them**:

```swift
func signOut() {
    d.set(false, forKey: "mrx_auth")
    d.set(false, forKey: "mrx_onboard")
    d.set(false, forKey: "mrx_pro")
    …
    TokenManager.shared.clear()
    // "mrx_progress_entries_v2" survives
    // "mrx_legal_acceptance_records" survives
    // "mrx_name" / "mrx_first" / "mrx_sport" / "mrx_explevel" / "mrx_phase" survive
}
```

The next athlete to sign in on that device inherits the previous athlete's readiness scores, pain levels, session history, streak, name, sport, and legal acceptances. `fetchFromCloud` merges remote entries **without filtering by `userId`**, so the foreign records persist through a cloud sync too. `LegalStore.clearLocal()` exists and is never called.

For a youth-athlete health app, this is a data-protection problem, not just a bug.

**One genuine positive:** the period selector logic is correct and real. `filteredEntries(period:)` maps 0→7, 1→30, default→90 days and filters against real `Date` values. Streaks and averages are computed from dated records, not counters. If the Progress tab's Week/Month/3-Month buttons don't work, **the defect is in the view, not this service** — and the view was not supplied.

### 4.8 `weekSessionsCount()` counts the wrong thing — MEDIUM

```swift
guard let weekStart = cal.date(from: comps) else { return entries.count }
return entries.filter { $0.date >= weekStart }.count
```

Counts **all** entries — readiness check-ins included — not sessions. A user who checks in daily and trains never shows 7 "sessions." The fallback returns the **all-time** count.

### 4.9 `currentStreak()` collapses to zero before the day's check-in — MEDIUM

The loop starts at `startOfDay(for: Date())` and breaks immediately if there is no entry today. An athlete with a 40-day streak sees **0** every morning until they check in. This is a product decision as much as a bug, but as written the number is misleading.

### 4.10 Stress is collected, stored, and ignored — MEDIUM

`evaluateReadiness` takes `stress` and never references it. The weights that are used sum to exactly 1.00 (0.30 + 0.25 + 0.15 + 0.12 + 0.10 + 0.08), so stress was deliberately removed from the formula but left in the signature — and `ProgressService.addReadinessEntry` still persists `stressLevel`. Either weight it or remove it from the intake.

### 4.11 `restoreSession` can leave a stale authenticated state — HIGH

```swift
} else if let user = try? await Amplify.Auth.getCurrentUser() {
    …
} else {
    return                      // <-- early return, no state change
}
```

If the session is signed in but `getCurrentUser()` fails (transient network), the function returns without setting `appState.isAuthenticated = false`. `AppState.load()` has already set it to `true` from `UserDefaults`. The user sees a normal signed-in app in which every API call 401s.

### 4.12 Legal acceptances are recorded against `"pending"` — HIGH

```swift
userId: userId.isEmpty ? "pending" : userId,
```

If acceptance happens before sign-in — which the onboarding order implies — every record is written under the literal string `"pending"` and **never reconciled** to the real Cognito `sub`. Additionally, `hasAccepted(_:version:)` ignores `userId` entirely, so any record on the device satisfies the check for any user.

Combined with `syncToSupabase` being an empty stub (§6.1), the practical position is: **MatReturnRx currently has no durable, attributable record that any athlete or parent accepted the Terms, Privacy Policy, Medical Disclaimer, Assumption of Risk, or Youth Athlete Waiver.** The records exist only in device `UserDefaults`, unattributed, and vanish on reinstall.

### 4.13 SwiftUI identity churn in the legal renderer — MEDIUM

```swift
struct LegalParagraph: Identifiable {
    let id = UUID()          // fresh UUID per instantiation
    …
}

struct LegalTextRenderer: View {
    var paragraphs: [LegalParagraph] { parse(content) }   // computed — re-parses every body pass
```

`paragraphs` is a **computed property**, so every `body` evaluation re-parses the entire document (the Terms of Service alone is ~250 lines) *and* mints brand-new `UUID`s. SwiftUI sees a completely fresh set of identities each time and rediffs the whole document. Result: wasted main-thread work while scrolling and unstable scroll position/animation.

Fix: derive `id` from content or index, and hoist the parse into a `let` or a cached `@State`.

### 4.14 Synchronous history decode on the launch path — MEDIUM

`AppState.init()` → `load()` → `ProgressService.shared` → `loadEntries()` synchronously JSON-decodes the **entire** progress history on the main thread during app initialization. There is no cap, pruning, or pagination — the array grows without bound, so launch cost grows with usage.

### 4.15 Smaller runtime items

- `ProgressService.fetchFromCloud(userId:appState:)` is **never called** from any supplied code path.
- `AppState.recordSession()` is an empty body with a "Superseded" comment — still public and callable.
- `TokenManager.clear()` removes `mrx_cognito_user_id` but leaves `mrx_user_role` behind.
- `filteredEntries` returns the **unfiltered** array if date arithmetic fails.
- `ForEach(para.bullets, id: \.self)` — duplicate bullet strings collide on identity.
- `AmplifyAPIManager.fetchProgress` sends `queryParameters: ["order": "created_at.asc"]` — PostgREST syntax (§6.2).

---

## SECTION 5 — Security Problems

### 5.1 What is genuinely clean

Worth stating plainly, because it is the strongest part of the codebase:

- **No hardcoded AWS credentials.** No `AKIA…`, no access key IDs, no secret access keys, no session tokens, no root or IAM credentials anywhere in the source or project files.
- **No AI provider keys.** No OpenAI/Anthropic/other API keys. AI calls go through the backend endpoint, which is the correct shape.
- **No force unwraps, no `try!`, no `as!`, no `fatalError()`** anywhere in ~2,100 lines. Genuinely disciplined.
- The only hardcoded backend values are a Cognito **hosted-domain URL** (public by design) and a placeholder app client ID (also public by design).

### 5.2 Findings

| # | Finding | Severity |
|---|---|---|
| **S1** | Amplify Gen 2 data model uses `allow.publicApiKey()` with `defaultAuthorizationMode: "apiKey"` — **anything in that table is readable and writable by anyone holding the API key**, no user identity required. Template default, but it is the only deployed authorization posture that exists. | **CRITICAL** |
| **S2** | Client-supplied identity: `GET /profiles/{userId}`, `GET /progress/{userId}`, and `CloudRequest.user_id` all take the user ID **from the client**. If the Lambda trusts the path/body instead of deriving `sub` from the verified Cognito JWT, **any authenticated athlete can read and overwrite any other athlete's profile and full medical-adjacent history by changing an ID**. The Lambda is not in the repo — I cannot verify which it does. Given placeholder-grade maturity elsewhere, assume unenforced until proven. | **CRITICAL** (unverified) |
| **S3** | Apple Sign In sets `isAuthenticated = true` locally without any valid AWS session; fabricates `UUID().uuidString` as identity on parse failure (§4.3). This is exactly the "local boolean as proof of authentication" pattern. | **CRITICAL** |
| **S4** | Pro entitlement resolves from `UserDefaults["mrx_pro"]` at launch; never revoked (§4.6). Editing one plist value grants permanent Pro. | **HIGH** |
| **S5** | `hydrateFromProfile` grants Pro on `is_pro: false` (§4.5). | **CRITICAL** |
| **S6** | Progress history, profile fields, name, sport, and legal acceptances survive sign-out and are not user-scoped — cross-account exposure of health-adjacent data on shared devices (§4.7). | **HIGH** |
| **S7** | Parent/guardian **names and email addresses for minor athletes** are stored in plain `UserDefaults`, never encrypted, never synced, never cleared. `UserDefaults` is not a secure store and is included in unencrypted device backups. | **HIGH** |
| **S8** | `AI` requests fall back to the literal user ID `"anonymous"`: `TokenManager.shared.userId ?? (appState.userId.isEmpty ? "anonymous" : appState.userId)`. Personalized health guidance dispatched with no identity. | **HIGH** |
| **S9** | `SecRandomCopyBytes` return value discarded → silently predictable nonce (§4.4). | **HIGH** |
| **S10** | Whether `Amplify.API` attaches the Cognito authorizer depends entirely on the absent `amplifyconfiguration.json`. If it is configured for `API_KEY` or `NONE`, every endpoint is open. **Cannot verify.** | **CRITICAL** (unverified) |
| **S11** | The Gen 2 API key is set to expire in 30 days (`expiresInDays: 30`). If anything ever depends on it, it breaks silently on a timer. | MEDIUM |

---

## SECTION 6 — Legacy Supabase Status

**Headline: there is no live Supabase integration.** No `SupabaseClient`, no `supabase-swift` package, no project URL, no anon key, no Supabase auth calls, no Supabase queries. **There is no dual-backend conflict at runtime.** AWS is already the sole backend path. That is better than the brief anticipated.

What remains is residue:

| Item | Location | Class | Recommendation |
|---|---|---|---|
| `private func syncToSupabase(_ record: LegalAcceptanceRecord) {}` — empty stub, called from `accept()` | `LegalContent.swift` | **OBSOLETE** (name) / **MISSING** (function) | Don't just delete. Legal acceptance has **no** backend persistence today (§4.12). Replace with a real AWS write, then remove the name. |
| `@Published var userId = "" // Supabase Auth user UUID` | `AppState.swift` | **OBSOLETE** | Delete comment |
| `// Called by AuthManager after a successful Supabase login/signup…` | `AppState.swift` | **OBSOLETE** | Delete comment |
| `queryParameters: ["order": "created_at.asc"]` in `fetchProgress` | `AmplifyService.swift` | **MIGRATING** | PostgREST/Supabase ordering syntax — meaningless to API Gateway. Silently ignored today; results arrive unordered. Move ordering server-side or sort client-side. |
| snake_case `CodingKeys` on `ProgressEntry`, `AthleteProfile`, `CloudRequest` | 3 files | **MIGRATING** | Postgres column-naming convention. Not wrong per se, but it is the direct cause of the `fetchProfile` decode failure (§4.2). Pick one convention and enforce it. |
| `Services/SupabaseService.swift` — the **filename** | project tree | **CONFLICTING** (name only) | The file at this path now appears to contain the AWS-facing `Cloud*` models and `CloudProcessingService`. It was repurposed and never renamed. Rename to `CloudProcessingService.swift`. **Needs confirmation against the real file — its header was missing from the dump.** |

**No Supabase package dependency exists to remove** (there are no package dependencies at all). Nothing in the Supabase cleanup list is blocking, and none of it should be deleted before the legal-sync replacement is written.

---

## SECTION 7 — Dead Code

Verified unreferenced **within the supplied subset**. `ContentView.swift` was not supplied, so items marked ⚠ must be re-checked against it before deletion.

| Item | Location | Note |
|---|---|---|
| Duplicate `AmplifyService.swift` block (~154 lines) | `AmplifyService.swift` | Redeclaration — see B5 |
| `AppState.recordSession()` | `AppState.swift` | Empty body, self-documented as superseded ⚠ |
| `LegalStore.syncToSupabase(_:)` | `LegalContent.swift` | Empty stub — **replace, don't delete** (§6) |
| `LegalStore.clearLocal()` | `LegalContent.swift` | Never called — **should be called from `signOut()`** (§4.7) |
| `TokenManager.clearSession()` | `AuthService.swift` | Pure alias for `clear()` ⚠ |
| `TokenManager.userRole` | `AuthService.swift` | Written, never read ⚠ |
| `AmplifyConfig.isConfigured` | `AmplifyService.swift` | Never read — the guard it was written for was never wired up ⚠ |
| `CloudErrorResponse` | Cloud service file | Never decoded anywhere ⚠ |
| `FeltResponse` | `CoreModels.swift` | Never referenced ⚠ |
| `LegalDocument.minorOnly` | `LegalContent.swift` | Never read — `all(isMinor:)` uses a hardcoded array instead |
| `Color.mrxCardLight` | `AppTheme.swift` | Never used |
| `sha256Nonce(_:)` | `AuthService.swift` | Defined but not used in the Apple path (§4.4) — **a symptom, not dead code** |
| `stress:` parameter | `evaluateReadiness` | Accepted, ignored (§4.10) |
| `Item.swift` | not supplied | Xcode SwiftData template file — almost certainly unused ⚠ |
| `MatReturnRx DevTests` / `DevUITests` | project | Both targets have **empty `Sources` phases** — zero tests exist |

---

## SECTION 8 — Architectural Problems

### 8.1 Three competing sources of truth for authentication

| Source | Where |
|---|---|
| Cognito session | `Amplify.Auth.fetchAuthSession()` — the only real one |
| `AppState.isAuthenticated` | `@Published Bool` |
| `UserDefaults["mrx_auth"]` | Read at launch, before any session check |
| `TokenManager.userId` | `UserDefaults`, `isAuthenticated` computed as `userId != nil` |

They are written in different orders in different code paths and can disagree — §4.3 and §4.11 are two concrete cases where they do.

### 8.2 Three competing sources of truth for entitlement

StoreKit vs `UserDefaults["mrx_pro"]` vs `AthleteProfile.is_pro` — see §4.6. The brief's requirement to separate *purchase state / verified entitlement / backend authorization / UI access state* is currently unmet: all four collapse into one mutable `Bool` on `AppState`.

### 8.3 Inverted dependency — services mutate view state

Nearly every service method takes `appState: AppState` and writes to it:

```swift
func signIn(email:password:appState: AppState) async throws
func addReadinessEntry(…, appState: AppState)
func purchase6Month(appState: AppState)
func processAction(…, appState: AppState) async throws -> CloudResponse
func restoreSession(appState: AppState) async
```

Services depend on presentation state instead of the reverse. Nothing can be unit-tested without constructing an `AppState`; there is no protocol boundary and no injection point. This — not file size — is the main obstacle to testability.

### 8.4 `AppState` is a god object

14 `@Published` properties spanning authentication, identity, profile, onboarding, entitlement, readiness result, streak counters, and **paywall presentation** (`showPaywall`). Any change to any one invalidates every view observing it.

### 8.5 Singleton sprawl with cross-singleton initialization

`AppState.init()` → `load()` reaches into `TokenManager.shared` and `ProgressService.shared`, whose own `init` performs disk I/O. Five `.shared` instances with no protocol abstraction and no lifecycle control. `LegalStore.init()` is additionally **public** alongside its `.shared`, so `@StateObject private var store = LegalStore.shared` in two views takes `@StateObject` ownership of a singleton — a state-management anti-pattern that should be `@ObservedObject` or an `@EnvironmentObject`.

### 8.6 ~1,000 lines of legal prose embedded in Swift

Five full legal documents live as Swift string literals inside `LegalContent.swift`. Consequences: a lawyer's comma change requires an App Store release; the text cannot be localized despite `LOCALIZATION_PREFERS_STRING_CATALOGS = YES` being set; and it inflates compile time for a file that also holds runtime logic. Move to bundled resources or a versioned remote document served from the backend (which also enables re-consent when a version bumps).

### 8.7 Backend generation mismatch

Gen 1 REST client vs Gen 2 AppSync backend — §2.3. This is the single largest architectural decision outstanding.

### 8.8 Monolithic `ContentView.swift`

Not supplied, but every screen, the navigation graph, and the shared component library live in it. It must be split — but **not before the source is available and building**.

---

## SECTION 9 — MUST FIX BEFORE LAUNCH

### CRITICAL — nothing ships until these are done

| # | Item | Ref |
|---|---|---|
| **L1** | **Decide the target platform.** The project is configured for macOS (`SDKROOT = macosx`); the code is iOS. Every other fix depends on this answer. | §1.1, B3, B4 |
| **L2** | **Get the actual source into the repository.** No audit, build, or fix can be completed against a `.xcodeproj` with no source files. | §0.1 |
| **L3** | **Add the Amplify Swift SPM dependency.** Nothing that imports Amplify compiles today. | B2 |
| **L4** | **Choose Gen 1 or Gen 2 and build the real backend.** No MatReturnRx data model is deployed anywhere. There is a `Todo` table. | §2.3 |
| **L5** | **Replace `allow.publicApiKey()` with owner-based authorization** on every model. | S1 |
| **L6** | **Derive user identity server-side from the verified Cognito JWT.** Never trust `{userId}` from the client. | S2 |
| **L7** | **Rewrite Apple Sign In** using `Amplify.Auth.signInWithWebUI(for: .apple)`. Remove the manual token exchange and the fabricated-UUID fallback. | §4.3, S3 |
| **L8** | **Make StoreKit the sole entitlement authority.** Delete `UserDefaults["mrx_pro"]` as a source of truth; revoke on the transaction listener; fix `if let pro = profile.isPro`. | §4.5, §4.6, S4, S5 |
| **L9** | **Fix the profile decode.** One key convention. `fetchProfile` returns `nil` 100% of the time today. | §4.2 |
| **L10** | **Persist legal acceptance to the backend, attributed to a real user ID.** No durable, attributable consent record exists today — for an app serving minors with waivers. | §4.12, S7 |
| **L11** | **Bundle `amplifyconfiguration.json` / `amplify_outputs.json`, and fail loudly if configuration fails** instead of `print`-and-continue. | §4.1, S10 |

### HIGH

| # | Item | Ref |
|---|---|---|
| **L12** | Scope all local data by user ID; clear progress, legal records, and profile keys on sign-out. | §4.7, S6 |
| **L13** | Make progress persistence server-authoritative with a real sync/outbox — stop swallowing write failures. | §4.7 |
| **L14** | Fix `restoreSession`'s early return leaving a stale authenticated state. | §4.11 |
| **L15** | Fix `randomNonceString` — check the `SecRandomCopyBytes` status, send the SHA-256 digest, complete the alphabet. | §4.4, S9 |
| **L16** | Remove the `"anonymous"` user-ID fallback in `CloudProcessingService`; require authentication. | S8 |
| **L17** | Delete the duplicated `AmplifyService` block (confirm against the on-disk file first). | B5 |
| **L18** | **Locate and remove `Double.random(in: 4...9)`** — not present in the supplied code; it is in `ContentView.swift`. | §0.4 |
| **L19** | Audit the Progress tab **view** for the Week/Month/3-Month selectors. The service layer is correct — the view was not supplied. | §4.7 |

### MEDIUM

`weekSessionsCount` counts check-ins as sessions (§4.8) · `currentStreak` reads 0 before today's check-in (§4.9) · stress collected but unweighted (§4.10) · `LegalParagraph` identity churn + computed re-parse (§4.13) · synchronous unbounded history decode at launch (§4.14) · `AuthError` shadows `Amplify.AuthError` (B8) · `deinit` concurrency (B9) · non-`Sendable` singletons (B10) · Gen 2 API key 30-day expiry (S11).

### LOW

Dead code cleanup (§7) · rename `SupabaseService.swift` (§6) · remove obsolete Supabase comments (§6) · `Color.mrxCardLight` (B11).

---

## BLOCKED — Required Before Work Can Proceed

I will not fabricate any of this.

**Blocking Phase 2 (build stabilization):**

1. **The complete source tree** — `ContentView.swift`, `MatReturnRx_DevApp.swift`, `Item.swift`, `Assets.xcassets`, and the on-disk copies of every file reconstructed in §0.2. Push the folder, not a zip of the `.xcodeproj`.
2. **Platform decision** — iOS or macOS.
3. **A macOS build host with Xcode** — this environment is Linux. I can read, reason, and write Swift; I cannot compile or run it. Every "verify the build" step in the brief has to happen on your machine or in CI (an `xcodebuild` GitHub Action would let me iterate against real compiler output).

**Blocking Phase 3 (backend consolidation):**

4. `amplifyconfiguration.json` **or** `amplify_outputs.json` — neither exists in either repo.
5. **Cognito user pool ID and app client ID** (`AmplifyConfig.appClientId` is `"REPLACE_WITH_APP_CLIENT_ID"`), and whether the hosted domain `matreturnrx.auth.us-east-1.amazoncognito.com` is real and deployed.
6. **Whether Apple is configured as a social IdP** on that user pool.
7. **Lambda source** for `/process-action`, `/profiles`, `/progress` — required to answer S2 (the IDOR question), and to know whether AI runs on Bedrock or an external provider. **There is no evidence of Bedrock anywhere in the code; I am not going to assume it.**
8. **API Gateway authorizer configuration** — Cognito authorizer, IAM, or none. Determines S10.
9. **Database schema** — table names, partition/sort keys, indexes. Nothing in either repo describes one.
10. **Gen 1 vs Gen 2 decision** (§2.3).

**Blocking Phase 4 (subscriptions):**

11. **App Store Connect status** of `pro_6_month_1499` and `pro_12_month_1099` — do these products exist and are they approved?
12. **A `.storekit` configuration file** — none in the project, so the purchase flow cannot be tested locally.

---

## Prioritized Repair Plan

Sequenced by dependency, not by severity — several critical items are simply unreachable until earlier ones land.

**Phase 2 — Build stabilization** *(blocked on items 1–3)*
Push the real source → add the Amplify SPM dependency → resolve the platform question → delete the duplicate `AmplifyService` block → compile → fix the resulting errors → **stand up CI so builds are actually verified.**

**Phase 3 — Backend consolidation** *(blocked on items 4–10)*
Commit the Amplify config → decide Gen 1 vs Gen 2 → model Profile / Readiness / Session / Entitlement for real → make `Amplify.configure()` failure loud → fix the profile decode → collapse auth to a single source of truth → route Apple Sign In through Amplify.

**Phase 4 — Security**
Owner-based authorization → server-derived identity → StoreKit as the sole entitlement authority → nonce fix → remove the `"anonymous"` fallback → per-user data scoping and sign-out teardown.

**Phase 5 — Functional repair**
Backend-persisted legal acceptance with real attribution → real progress sync with retry → `weekSessionsCount` / `currentStreak` corrections → stress weighting decision → locate and remove `Double.random` → repair the Progress tab view.

**Phase 6 — Dead code cleanup**
Only after §7's ⚠ items are re-checked against `ContentView.swift`.

**Phase 7 — Architectural refactor**
Split `ContentView.swift` → introduce protocol boundaries so services stop mutating `AppState` → break up `AppState` → move legal prose out of Swift.

**Phase 8–10 — Validation, performance, release audit**
Requires a build host. `LegalParagraph` identity, the computed re-parse, and the launch-path decode are the three concrete performance items already identified.

---

## Honest Status Summary

| Claim | Status |
|---|---|
| Xcode builds successfully | **Cannot be assessed** — no source, no build host |
| App launches without crashing | **Cannot be assessed** |
| Navigation works | **Cannot be assessed** — `ContentView.swift` not supplied |
| AWS is the single backend | **True in the client code.** No Supabase integration remains. |
| AWS backend is functional | **No.** Not configured, not linked, and the data model does not exist. |
| Authentication works | **No.** Not linked, not configured; Apple Sign In cannot work as written. |
| Progress data is real | **Partly.** The service computes from real dated records; persistence is device-local and leaks across accounts. |
| Subscription entitlement is reliable | **No.** Three competing sources; grants on `false`; never revokes. |
| Secrets exposed | **None found.** Genuinely clean. |
| Legal/PT content is sound | **Yes.** Disclaimers, safety warnings, and evidence panels are present and appropriately scoped. Consent *persistence* is the problem, not the content. |

**Launch blockers remain. The application is not close to launch-ready.** The most consequential fact is not any single defect — it is that the backend the app is written against has not been built, and the source needed to verify anything is not in the repository.

---

*Phase 1 complete. No code was modified. Awaiting approval and the blocked items above before beginning Phase 2.*
