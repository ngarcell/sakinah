# TrueMax — App Flow and Architecture

**Reviewed:** 19 July 2026

## Runtime graph

```text
SakinahApp
 ├─ ModelBootstrap
 │   ├─ protected Application Support/TrueMaxLocalData
 │   ├─ SwiftData cloudKitDatabase: .none
 │   └─ blocking storage error if the protected store cannot be created
 ├─ RevenueCat SubscriptionService (existing keys/products/entitlement)
 └─ ContentView
     ├─ onboarding gate (version + adult gate + premium disclaimer)
     ├─ TrueMaxPaywallView (custom SwiftUI)
     └─ MainTabView
         ├─ Home
         ├─ Scan
         ├─ History
         ├─ Styles
         └─ Settings
```

## First launch

```text
Launch
 ├─ local store opens? ─ no → explain storage failure; block app
 └─ yes
     ├─ onboarding current? ─ yes → entitlement check → tabs or paywall
     └─ no
         → Welcome → How it works → 18+ age gate → Privacy
         → custom paywall → purchase/restore → tabs
```

`completeOnboarding()` persists the onboarding version. The medical/cosmetic
disclaimer is a persisted first-premium-view acknowledgement, not a transient
flag, so force-quitting cannot silently skip it.

## Capture and analysis

```text
Checklist
  → camera permission
  → TrueDepth-capable front camera? ─ yes → depth-assisted capture
                              └─ no/failure → explicit Photo mode
  → AVCapturePhotoOutput still image
  → transient compact depth summary (never persisted)
  → Vision landmarks + face-capture quality
  → dynamic uncertainty profile (quality, pose, face area, depth reliability)
  → metric bands + quality note + deterministic guidance
  → JPEG + SwiftData record saved locally
```

`TrueMaxAnalysisEngine` keeps the raw image/depth boundary on-device. TrueDepth
only narrows symmetry, proportion, and jaw uncertainty where its compact
regional summary is reliable; canthal tilt and visible texture remain image
measurements. No value is called clinical, high-precision, or an attractiveness
score.

## Local intelligence

`TrueMaxKnowledgeBase` stores reviewed platform/guardrail entries and a release
revision. `TrueMaxIntelligenceEngine` consumes a `ScanRecord` and returns
explainable signals with knowledge IDs. It is deterministic and offline; no
runtime document crawler, remote LLM, face upload, or RevenueCat attribute is
allowed. A knowledge update is shipped as code/docs with a new review date.

## Subscription flow

`SubscriptionService` preserves the live RevenueCat configuration and product
IDs. The custom paywall reads localized StoreKit/RevenueCat product details,
selects annual by default, checks introductory-offer eligibility for the
selected plan, and only then enables “Start Free Trial.” Unknown eligibility is
not treated as eligible. Purchases, restores, expiration, and refunds are
verified through the existing entitlement stream.

## Persistence and deletion

The app creates a dedicated, backup-excluded directory with complete file
protection. A scan save is transactional: if SwiftData fails, a newly written
JPEG is removed; if cleanup fails, the user sees a retry path. Deletion commits
the database change before removing protected files and reports partial cleanup
instead of claiming completion. Delete All is idempotent and never touches
Apple subscription state.

## Release checks

Run `python3 scripts/verify_truemax_contracts.py`, `git diff --check`, the
Swift parser gate, and plist/JSON parsing on Linux. On macOS, build both
configurations, run unit/UI tests, test physical TrueDepth and photo fallback,
exercise both RevenueCat products and the three-day introductory offer in
sandbox, and perform VoiceOver, Dynamic Type, contrast, and deletion tests.
