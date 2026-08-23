# MatReturnRx

**Built for Grapplers. Engineered by PT Science.**

Physical-therapy-informed injury prevention, mobility, recovery, and strength
programming for grapplers and wrestlers. SwiftUI on iOS, AWS Amplify Gen 2 on
the backend.

> **Pre-launch.** This project is not shippable yet. See
> [AUDIT.md](AUDIT.md) for the full technical audit and
> [SETUP.md](SETUP.md) for what is still blocked.

---

## Repository layout

```
.
├── MatReturnRx Dev.xcodeproj/     iOS app project (iOS 18.0+)
├── MatReturnRx Dev/               Swift sources — NOT YET COMMITTED (see below)
├── amplify/                       AWS Amplify Gen 2 backend
│   ├── auth/resource.ts           Cognito user pool
│   ├── data/resource.ts           Data models + custom mutations
│   ├── functions/
│   │   ├── process-action/        AI planning (Lambda)
│   │   └── verify-purchase/       StoreKit verification (Lambda)
│   └── backend.ts
├── .github/workflows/ci.yml       Backend typecheck + iOS build
├── AUDIT.md                       Phase 1 technical audit
└── SETUP.md                       Configuration and blocked items
```

### The app sources are missing

`MatReturnRx Dev/` is not in this repository. The Xcode project references it
through a `PBXFileSystemSynchronizedRootGroup`, so opening the project today
gives you three targets with zero source files. Committing that folder is the
single largest blocker — see [SETUP.md](SETUP.md).

---

## Architecture

```
iOS app (SwiftUI)
      │  Amplify Swift 2.60+
      ▼
Amazon Cognito user pool ──────────── authentication
      │
      ▼
AWS AppSync (GraphQL) ─────────────── all CRUD, owner-scoped
      │
      ├─► Amazon DynamoDB ─────────── UserProfile, ReadinessEntry,
      │                               SessionEntry, LegalAcceptance,
      │                               Entitlement
      │
      ├─► Lambda: process-action ──── AI planning        [not configured]
      └─► Lambda: verify-purchase ─── StoreKit + Apple   [not configured]
```

One backend. Amplify Gen 2 handles CRUD; Lambda is used only where it is
genuinely required — talking to an AI provider and verifying purchases with
Apple. There is no second data path.

### Authorization

`defaultAuthorizationMode` is `userPool`; nothing is reachable without a signed-in
user. Every athlete model uses `allow.owner()`, so AppSync resolves identity
from the verified Cognito JWT rather than from anything the client sends.

Two models deviate deliberately:

| Model | Rule | Why |
| --- | --- | --- |
| `LegalAcceptance` | owner: create + read | A consent record that can be edited afterward is not a consent record. |
| `Entitlement` | owner: read only | Only `verify-purchase` may grant Pro. A device cannot entitle itself. |

---

## Local development

### Backend

Requires Node 22+ and AWS credentials with permission to deploy Amplify.

```bash
npm install          # not `npm ci` — see the note in .github/workflows/ci.yml
npx tsc --noEmit     # typecheck
npx ampx sandbox     # deploy a personal sandbox stack
```

`ampx sandbox` writes `amplify_outputs.json`. That file is gitignored and must
never be committed — it is per-environment configuration, and the iOS app reads
it at runtime.

### iOS app

Requires Xcode 26+ and macOS. Open `MatReturnRx Dev.xcodeproj`; Swift Package
Manager resolves `aws-amplify/amplify-swift` on first open.

The app target links three products: `Amplify`, `AWSCognitoAuthPlugin`, and
`AWSAPIPlugin`.

---

## Continuous integration

`.github/workflows/ci.yml` runs on every push and pull request.

| Job | Runner | What it does |
| --- | --- | --- |
| `Backend · typecheck` | `ubuntu-latest` | Typechecks the Amplify definitions and confirms the schema constructs. |
| `iOS · build` | `macos-15` | Builds and tests the app. |

The iOS job currently **skips with a warning** because there are no Swift
sources to build. A green `iOS · build` does not yet mean anything.

---

## Medical and safety positioning

MatReturnRx provides **educational performance and recovery guidance**. It does
not diagnose, treat, replace medical care, or provide return-to-play clearance.

This is not boilerplate — it is enforced in code. `process-action` gates on
reported pain **before** any model is called: at or above the referral
threshold it returns a referral, never a training plan. Every module carries an
evidence panel and every exercise a safety warning.

Content changes touching disclaimers, waivers, or the `D` constants in
`CoreModels.swift` should go through legal review.

---

## Subscription tiers

**Basic** — Mobility & Recovery, Knee Starter, Neck Starter, Shoulder Starter,
Hip & Groin Injury Prevention, Lower Back Injury Prevention.

**Pro** — adds Grappling Strength Foundation and Return to Mat Protocol, plus
personalized programming.

Products: `pro_6_month_1499`, `pro_12_month_1099`. Entitlement is resolved from
StoreKit and verified server-side; it is never read from local storage.
