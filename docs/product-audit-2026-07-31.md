# TrueMax product and code audit

**Date:** 31 July 2026

**Repository:** `/home/qpay/sakinah`

**Branch audited:** `main`

**Product model:** adult-only reverse-trial onboarding, one real result, then a
hard paywall; no freemium; three-day trial on the annual plan only when
StoreKit confirms eligibility.

## Executive assessment

The audited build had two critical product bypasses, several high-impact
privacy/reliability gaps, and a mismatch between its workspace access rules and
the required hard-paywall model. The product-code issues found in scope have
been fixed. The app now:

- requires the adult/privacy path and a real scan instead of exposing seeded
  demo data through a shipping Skip action;
- consumes the one-result allowance when the result is saved, preventing a
  force-quit from granting repeated scans;
- gives completed users workspace access only with an active entitlement;
- sends no product analytics, matching the published privacy policy;
- handles camera startup and local persistence failures visibly;
- protects local capture filenames and normalizes corrupt measurement ranges;
- makes guidance cards actionable and improves state, accessibility, and
  performance behavior.

The critical paywall truthfulness defect identified below was resolved in a
separately authorized, narrowly scoped commercial follow-up. The Declared Age
Range entitlement remains missing from the protected signing configuration.

## Scope and method

The audit covered the SwiftUI application shell, onboarding, age gate, camera
and analysis pipeline, SwiftData persistence, history, style and color tools,
settings/data controls, accessibility semantics, analytics boundary, tests,
release contracts, public support/legal endpoints, and read-only inspection of
the protected purchase path.

Checks included:

- source and architecture review of every shipping Swift area;
- end-to-end state tracing for fresh, underage, reverse-trial, premium,
  ineligible-trial, lapsed, camera-failure, save-failure, deletion, and
  marketing-demo paths;
- Swift syntax parsing with Tree-sitter/ast-grep;
- repository contract and intelligence verification;
- property-list and JSON validation;
- unsafe-pattern, swallowed-error, path-handling, and dependency review;
- HTTP checks of the live
  [Privacy](https://socialreporthq.com/sakinah/privacy),
  [Terms](https://socialreporthq.com/sakinah/terms), and
  [Support](https://socialreporthq.com/sakinah/support) pages.

## Findings fixed

### Critical

| ID | Category and location | Problem, impact, and reproduction | Resolution |
|---|---|---|---|
| C-01 | Access control — `ios/Sakinah/ContentView.swift:27`, `ios/Sakinah/TrueMax/TrueMaxOnboardingFlow.swift:94` | The welcome-screen **Skip** action marked onboarding complete and opened a seeded marketing workspace. **Impact:** bypassed the adult gate, privacy preparation, real reverse-trial scan, and hard paywall. **Reproduce before fix:** fresh install → tap Skip → play/explore demo → access tabs and synthetic records. | Removed the shipping Skip path and post-purchase demo launcher. The marketing walkthrough is available only with the explicit `-TrueMaxMarketingDemo` recording argument. A UI assertion and release-contract check prevent regression. |
| C-02 | Reverse-trial integrity — `ios/Sakinah/TrueMax/TrueMaxScanFlow.swift:792`, `ios/Sakinah/TrueMax/TrueMaxAppState.swift:146` | The allowance was consumed only after tapping Done. **Impact:** a user could save/view a result, force-quit, relaunch, and obtain repeated free scans. **Reproduce before fix:** complete first scan → wait for result → force-quit before Done → relaunch and scan again. | Persist the consumed state immediately after the SwiftData save succeeds. Paywall presentation remains deferred until Done, preserving full result review without reopening the allowance. |

### High

| ID | Category and location | Problem, impact, and reproduction | Resolution |
|---|---|---|---|
| H-01 | Product model — `ios/Sakinah/ContentView.swift:30` | Completed non-premium users entered the main tabs unless a transient `presentsPaywall` flag happened to be set. **Impact:** a freemium/lapsed workspace contradicted the required hard-paywall model. **Reproduce before fix:** complete onboarding while entitled → let entitlement lapse → relaunch → Home/History remained accessible. | The completed workspace now requires `isPremium`; otherwise the root renders a non-dismissible paywall. The launch-argument-only marketing playback is isolated from this shipping rule. |
| H-02 | Privacy — `ios/Sakinah/Services/TrueMaxAnalytics.swift:3` | The app initialized PostHog even though the PRD and live privacy policy promise no analytics and identify only Apple/RevenueCat data processing. Autocapture could also expose visible control labels. **Impact:** undisclosed network collection and privacy-policy inconsistency. **Reproduce before fix:** launch with a network proxy → observe PostHog setup/event traffic; compare with the live Privacy page. | `TrueMaxAnalytics` is now a no-op compatibility facade: no SDK setup, persistence, capture, or network transmission. Existing call sites remain so protected commercial files did not need modification. |
| H-03 | Onboarding delivery — `ios/Sakinah/TrueMax/TrueMaxOnboardingFlow.swift:54` | An already-premium user’s “Start your first scan” action completed onboarding without opening the scan. **Impact:** the app failed its baseline-first value promise and landed the customer on an empty workspace. **Reproduce before fix:** restore entitlement before onboarding → continue from Privacy. | Premium and reverse-trial users now both enter the real scan. Premium onboarding completes only after a saved result. |
| H-04 | Camera reliability — `ios/Sakinah/TrueMax/TrueMaxScanFlow.swift:713` | An authorized but failed configuration/start was treated as success. **Impact:** the user reached a camera UI that could never capture, with no actionable error. **Reproduce before fix:** force front-camera configuration/start failure after authorization. | Check `isConfigured` and `isRunning` after the awaited preparation, stop the failed pipeline, return to the checklist, show the localized error, and allow retry. |
| H-05 | Safety communication — `ios/Sakinah/ContentView.swift:64`, `ios/Sakinah/TrueMax/TrueMaxAppState.swift:116` | Persisted medical-disclaimer state existed but no production view consumed it. **Impact:** users could miss a required statement that estimates are cosmetic, non-diagnostic, and not attractiveness scores. **Reproduce before fix:** finish onboarding and inspect the first workspace view. | Added a required persisted acknowledgement alert. Result pages retain contextual disclaimer copy as well. |

### Medium

| ID | Category and location | Problem, impact, and reproduction | Resolution |
|---|---|---|---|
| M-01 | Age-gate correctness — `ios/Sakinah/TrueMax/TrueMaxOnboardingFlow.swift:466` | Declined sharing and ambiguous ranges were treated as underage. **Impact:** adults in unsupported/non-regulated cases were incorrectly blocked. **Reproduce before fix:** decline Declared Age Range sharing where the API permits it. | Only a confirmed `upperBound < 18` blocks. Declined, unavailable, failed, and ambiguous responses fall back to explicit 18+ self-attestation. |
| M-02 | Persistence — `ios/Sakinah/TrueMax/TrueMaxModels.swift:354`, `ios/Sakinah/TrueMax/TrueMaxStyleViews.swift:485` | Favorite changes used `try?`, silently discarded save failures, and could leave duplicate style IDs. **Impact:** visible state could disagree with storage and duplicate records inflated counts. **Reproduce before fix:** inject a SwiftData save failure or insert duplicate favorites, then toggle. | Centralized transactional toggle, rollback on failure, removal of legacy duplicates, visible error alerts, and in-memory SwiftData tests. |
| M-03 | Local-file security — `ios/Sakinah/TrueMax/TrueMaxStorage.swift:50`, `ios/Sakinah/TrueMax/TrueMaxStorage.swift:191` | Image load accepted any stored path-like filename, while deletion used only a partial path-component check. **Impact:** corrupted/tampered local records could address unintended JPEG paths in Application Support. | Load, existence, and delete now require the exact app-generated `<UUID>.jpg` filename form. |
| M-04 | Data integrity — `ios/Sakinah/TrueMax/TrueMaxModels.swift:151`, `ios/Sakinah/TrueMax/TrueMaxModels.swift:162` | Non-finite or reversed ranges could reach display/conversion code; decoded stored ranges bypassed construction-time normalization. **Impact:** malformed persistence could produce invalid ranges or numeric conversion traps. | Normalize both constructed and decoded values to finite, ordered bounds; added constructor and JSON-decoding tests. |
| M-05 | Product navigation — `ios/Sakinah/TrueMax/TrueMaxHomeView.swift:163` | Guidance cards displayed chevrons but were inert. **Impact:** the primary “what to do next” value proposition appeared broken. **Reproduce before fix:** Home → tap a weekly guidance card → nothing happens. | Cards are now NavigationLinks into the full action plan with an accessibility hint. |
| M-06 | Performance — `ios/Sakinah/TrueMax/TrueMaxStyleViews.swift:713`, `ios/Sakinah/TrueMax/TrueMaxStyleViews.swift:981` | Color analysis reloaded the capture and created a new `CIContext` whenever SwiftUI reevaluated `body`. **Impact:** avoidable image I/O, GPU/context allocation, and scrolling/render churn. | Compute the profile once per view initialization and reuse a static Core Image context. |

### Low

| ID | Category and location | Problem and impact | Resolution |
|---|---|---|---|
| L-01 | Accessibility — `ios/Sakinah/TrueMax/TrueMaxHistoryView.swift:403` | Comparison VoiceOver always said “older left, newer right,” even after Swap. | Announce the actual left/right dates. |
| L-02 | Product semantics — `ios/Sakinah/TrueMax/TrueMaxHistoryView.swift:578` | Any measurement shift was green, implying improvement despite the no-ranking promise. | Use neutral accent styling for change. |
| L-03 | Data accuracy — `ios/Sakinah/TrueMax/TrueMaxSettingsView.swift:580` | “Photos saved” counted a non-null filename even when the file was absent or invalid. | Count only validated files that exist. |
| L-04 | Compatibility — `ios/Sakinah/TrueMax/TrueMaxModels.swift:4` | The audit initially misclassified `SubscriptionTier.free` as an unused freemium concept, but `SubscriptionService` requires its persisted raw value for “no active entitlement.” Removing it caused a compile failure. | Restored the compatibility enum and documented that `.free` means locked/no entitlement; the root hard paywall still prevents freemium access. |

## Protected-owner findings and follow-up status

### Critical

#### P-01 — Resolved: ineligible annual customers were promised a free trial

- **Category:** commercial truthfulness / billing UX
- **Location:** `ios/Sakinah/TrueMax/TrueMaxPaywallView.swift:323-383` and
  `ios/Sakinah/TrueMax/TrueMaxPaywallView.swift:387-400`
- **Original problem:** `.ineligible` and `.noIntroOfferExists` resolved
  correctly, but every non-error annual state rendered “Start 3-Day Free
  Trial,” an annual free-trial disclosure, and “3 days free” on the card.
- **Original impact:** false purchase claim for existing/ineligible customers,
  direct conflict with “annual only and only when eligible,” customer harm, and
  App Review/compliance risk.
- **Original reproduction:** use an Apple sandbox account that already consumed the
  introductory offer (or an annual product without an intro offer) → open the
  paywall → wait for eligibility to resolve → select annual → observe the
  three-day-trial CTA and disclosure.
- **Resolution:** trial CTA, plan-card detail, and billing disclosure now appear
  only for `.eligible`. Ineligible/no-offer customers see “Continue Pro —
  Annual,” immediate billing terms, and can purchase without a false trial
  claim. Unknown eligibility remains retry-only. Monthly never checks or
  mentions trial eligibility.

### High

#### P-02 — Declared Age Range capability is not signed into the app

- **Category:** production capability / age safety
- **Location:** `ios/Sakinah/Sakinah.entitlements:1-6`; calling code at
  `ios/Sakinah/TrueMax/TrueMaxOnboardingFlow.swift:466-486`
- **Problem:** the entitlement file is empty, so
  `com.apple.developer.declared-age-range` is absent even though the iOS 26 path
  requests the API.
- **Impact:** the promised privacy-preserving system age signal will fall back
  to self-attestation rather than operate in eligible environments.
- **Reproduction:** inspect a signed archive’s entitlements, or run the iOS 26
  age-range action on a configured physical device.
- **Required fix:** enable Declared Age Range in the Apple developer/App ID and
  target signing capability, then verify the signed archive. See Apple’s
  [Declared Age Range request documentation](https://developer.apple.com/documentation/declaredagerange/requesting-people-share-their-age-range-with-your-app).
- **Why unchanged:** entitlements and production signing configuration were
  explicitly excluded.

### Medium

#### P-03 — Landscape camera rotation is hard-coded to portrait

- **Category:** camera UX / orientation
- **Location:** `ios/Sakinah/Info.plist:67-78` and
  `ios/Sakinah/TrueMax/CameraCapture.swift:870-890`,
  `ios/Sakinah/TrueMax/CameraCapture.swift:1366-1371`
- **Problem:** the app declares landscape support while preview, video sample,
  and photo connections always request a 90-degree rotation.
- **Impact:** likely rotated/misaligned preview guidance or captures in
  landscape; exact sensor behavior requires physical-device confirmation.
- **Reproduction:** rotate a physical device to each supported landscape
  orientation during checklist/capture and compare preview, face guide, saved
  JPEG, landmarks, and depth alignment.
- **Required fix:** either make capture rotation scene-orientation-aware or
  constrain the capture experience to portrait. This was not changed without
  the required device/Xcode validation and because the alternative touches
  protected production orientation configuration.

#### P-04 — Release privacy declarations require an archive-level review

- **Category:** App Store privacy
- **Location:** `ios/Sakinah/PrivacyInfo.xcprivacy:5-27` and
  `ios/Sakinah.xcodeproj/project.pbxproj:309-315`
- **Problem:** the app manifest declares no collected data, while RevenueCat
  and a now-dormant PostHog package remain linked and may contribute their own
  manifests. The source audit cannot prove the merged archive report or App
  Store Connect answers.
- **Impact:** inaccurate release disclosures if the final SDK manifests,
  purchase identifiers, and App Store privacy answers diverge.
- **Required fix:** generate Xcode’s privacy report from the exact Release
  archive and reconcile it with App Store Connect. Apple documents that
  third-party SDKs supply their own manifests and that privacy answers must
  reflect actual collection:
  [privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
  and [App Privacy details](https://developer.apple.com/app-store/app-privacy-details/).
- **Why unchanged:** the manifest and production/App Store configuration were
  excluded.

#### P-05 — Pinned source documents retain obsolete product rules

- **Category:** architecture / maintainability
- **Location:** `docs/01-PRD (1).md:47-48` and
  `docs/03-App-Flow-Architecture.md:33-34`
- **Problem:** the pinned PRD still describes non-subscriber result/history
  access, and the architecture diagram omits the reverse-trial scan before the
  paywall. Both conflict with the explicit no-freemium override and shipping
  implementation.
- **Impact:** a future maintainer could reintroduce the wrong access model or
  onboarding order.
- **Required fix:** publish a new versioned source-of-truth document and update
  the verifier hashes through the repository’s controlled document process.
- **Why unchanged:** these supplied documents are hash-pinned release inputs.
  README and operational strategy documentation now state the current override.

### Low

#### P-06 — Dependency resolution is not reproducible

- **Category:** build maintainability / supply chain
- **Location:** `ios/.gitignore:24` and
  `ios/Sakinah.xcodeproj/project.pbxproj:301-315`
- **Problem:** `Package.resolved` is ignored and both packages use
  up-to-next-major ranges.
- **Impact:** clean machines can resolve different dependency versions,
  changing build output and privacy manifests.
- **Required fix:** adopt the team’s approved lockfile/update policy. Removing
  the dormant PostHog package would also reduce binary and supply-chain surface.
- **Why unchanged:** dependency and project configuration changes were excluded.

#### P-07 — Public legal copy needs editorial cleanup

- **Category:** external product trust
- **Location:** live
  [Privacy](https://socialreporthq.com/sakinah/privacy) and
  [Terms](https://socialreporthq.com/sakinah/terms) pages
- **Problem:** phrases such as “a in-app purchases” and “recurring and
  recurring” are malformed; the terms should state explicitly that only the
  eligible annual plan has a three-day trial.
- **Impact:** avoidable ambiguity in customer-facing legal/billing copy.
- **Required fix:** edit and legally review the external site content.
- **Why unchanged:** the website is outside this repository and is a production
  system.

## End-to-end flow result

| Flow | Audit result |
|---|---|
| Fresh adult onboarding | Gates cannot be skipped; real scan precedes plans. |
| Underage / ambiguous system age | Confirmed underage is blocked; ambiguous/declined falls back to self-attestation. Signed entitlement still needs configuration. |
| Reverse-trial save and force-quit | Allowance persists at successful save; no repeat free scan. |
| Reverse-trial result to plans | Result remains reviewable; Done leads to paywall. |
| Premium onboarding | Still performs and saves the promised first scan. |
| Returning/lapsed non-premium | Non-dismissible hard paywall; no freemium workspace. |
| Camera denied/restricted/start failure | Dedicated permission or retryable visible error path. |
| Database save failure | Transaction rolls back and capture cleanup is attempted; error is shown. |
| Individual/all-data deletion | Local records and validated capture files are deleted with surfaced failures. |
| Style favorite toggle | Transactional, duplicate-cleaning, visible failure path. |
| History comparison | Correct left/right accessibility state after swap; neutral change semantics. |
| Marketing walkthrough | Launch-argument-only and excluded from shipping onboarding/purchase paths. |
| Trial eligibility | Source behavior fixed: eligible annual shows the trial; ineligible annual shows immediate billing; unknown retries; monthly has no trial. StoreKit sandbox confirmation remains required. |

## Validation evidence

- `python3 scripts/verify_truemax_contracts.py` — **24/24 passed**
- `python3 scripts/verify_truemax_intelligence.py` — **passed**
- ast-grep Swift parse pass — **0 command/parse failures across Swift sources**
- `git diff --check` — **passed**
- public Privacy, Terms, Support endpoints — **HTTP 200**
- production configuration diff check — **no modifications**

Xcode, Swift, and `xcodebuild` are not available in this WSL environment.
Therefore a native compile, XCTest/UI test execution, signed-entitlement
inspection, StoreKit sandbox verification, VoiceOver/Dynamic Type pass, and
physical TrueDepth/2D/orientation testing remain mandatory before release.
Passing source contracts is not a substitute for those checks.

## Production configuration and remaining commercial files left unchanged

- `ios/Sakinah/Services/SubscriptionService.swift`
- `ios/Sakinah/Services/RevenueCatConfiguration.swift`
- `ios/Sakinah/Info.plist`
- `ios/Sakinah/Sakinah.entitlements`
- `ios/Sakinah/PrivacyInfo.xcprivacy`
- `ios/Sakinah.xcodeproj/project.pbxproj`
