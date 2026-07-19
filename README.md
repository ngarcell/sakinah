# TrueMax

TrueMax is a native iOS app for private, on-device facial measurement and
grooming/style guidance. It replaces the previous Sakinah product inside the
existing live iOS application identity. The App Store bundle and RevenueCat
catalog are therefore release contracts, not renameable implementation details.

The product is intended for adults. It presents supported facial measurements
as transparent estimate bands with plain-language methodology, avoids public ratings and
comparison mechanics, and does not provide medical, dermatological, dietary,
pharmacological, or psychological advice.

## Source of truth

Use these inputs in this order:

1. The user's explicit overrides: the display brand is **TrueMax**; preserve the
   existing RevenueCat monthly and annual subscriptions; use a custom paywall
   with annual selected by default; use no authentication; and keep facial data
   on device.
2. [`docs/01-PRD (1).md`](docs/01-PRD%20(1).md)
3. [`docs/02-UIUX-Specification.md`](docs/02-UIUX-Specification.md)
4. [`docs/03-App-Flow-Architecture.md`](docs/03-App-Flow-Architecture.md)
5. The 23 supplied design-reference PNGs and `docs/ios app icon.png`.

The documents were originally supplied with a provisional **Facet** working
title and a one-time-purchase proposal. Those two points are superseded by the
user's TrueMax and RevenueCat subscription instructions. This repository's
implementation and App Store metadata are the current release source of truth
for the brand, subscriptions, trial copy, and URLs.

`docs/brand-direction.md` and `docs/competitor-audit.md` were intentionally
removed during the product replacement. Do not restore them.

## Protected live-app contracts

- App bundle ID: `com.socialreporthq.sakinah`
- Unit-test bundle ID: `com.socialreporthq.sakinah.tests`
- UI-test bundle ID: `com.socialreporthq.sakinah.uitests`
- RevenueCat entitlement: `Sakinah Premium`
- RevenueCat fallback entitlement: `premium`
- Monthly product: `com.socialreporthq.sakinah.premium.monthly`
- Annual product: `com.socialreporthq.sakinah.premium.annual`
- Legacy lifetime product: `com.socialreporthq.sakinah.premium.lifetimev2`

Monthly and annual are the only plans sold on the TrueMax paywall. The lifetime
product remains recognized for restoration and backwards compatibility but is
not offered to new purchasers. RevenueCat must be configured anonymously; no
face capture, measurement, coaching result, age signal, or local-history field
may be attached as a subscriber attribute.

The paywall is native custom SwiftUI. It displays live localized StoreKit
pricing, selects annual by default, allows monthly selection, restores
purchases, and changes trial copy only when the selected product has a real
introductory offer for which the customer is eligible. Hosted
`RevenueCatUI.PaywallView` UI is not part of the active TrueMax flow.

## Local intelligence layer

`TrueMaxIntelligenceLayer.swift` is a versioned, bundled knowledge base and
deterministic rule engine. It maps current Apple Vision/AVFoundation capture
guidance, age/privacy requirements, App Store safety boundaries, and AI
traceability practices into explainable action-plan signals. The source registry
is [`docs/truemax-intelligence-sources.json`](docs/truemax-intelligence-sources.json)
and is checked by `scripts/verify_truemax_intelligence.py`. It has no network
fetch, no raw image input, and no subscriber attributes. Updating the knowledge
revision is an explicit release change that must be reviewed alongside the
privacy manifest and App Store disclosures.

## Privacy boundary

Face captures, geometry, measurements, coaching, and history are processed and
stored locally with no account or cloud sync. RevenueCat and Apple necessarily
use network communication for product loading, purchases, restoration, and
entitlement verification. Product copy must therefore say that **facial data
stays on device**, not that the entire app makes zero network calls.

The active TrueMax runtime must not use:

- CloudKit or iCloud data sync
- Sign in with Apple or any other authentication
- advertising or third-party analytics
- remote face-analysis/model APIs
- public ratings, leaderboards, social comparison, or generated idealized faces

On iOS 26 and newer, the onboarding gate requests Apple’s privacy-preserving
Declared Age Range signal through the
`com.apple.developer.declared-age-range` capability. Older systems, unavailable
regions, and API failures use the explicit 18+ self-attestation fallback. The
app never receives or stores an exact birth date.

SwiftData must use an explicit local `ModelConfiguration` with
`cloudKitDatabase: .none`. RevenueCat remains the source of truth for purchase
and entitlement state, using its existing cached `CustomerInfo`, refresh, and
customer-information update stream.

## Repository layout

- `ios/Sakinah/` — live native iOS target and retained RevenueCat services
- `ios/SakinahTests/` — unit and contract-oriented tests
- `ios/SakinahUITests/` — launch and critical-flow UI tests
- `docs/` — product sources, supplied visual references, and App Store metadata
- `scripts/verify_truemax_contracts.py` — Linux-runnable release-contract gate
- `scripts/verify_truemax_intelligence.py` — evidence-pack and offline-boundary gate

The target name and folder remain `Sakinah` to avoid destabilizing the existing
project identity. The user-facing display name is TrueMax.

## Build and verification

Run the fast contract gate from the repository root:

```bash
python3 scripts/verify_truemax_contracts.py
python3 scripts/verify_truemax_intelligence.py
```

The verifier protects identifiers, RevenueCat configuration, the custom
annual-default paywall contract, local-only data boundaries, supplied source
documents/images, and app-icon handoff. It intentionally fails when the
replacement is incomplete.

The script does not replace an Xcode build. Before release, use the repository's
supported Xcode version on macOS to:

1. Build Debug and Release configurations.
2. Run unit and UI tests.
3. Exercise TrueDepth and 2D fallback capture on physical devices.
4. Test monthly and annual purchases, trial eligibility, cancellation,
   restoration, expiration, refund, and offline entitlement boundaries in the
   Apple/RevenueCat sandbox.
5. Run VoiceOver, Dynamic Type, Reduce Motion, contrast, and iPad layout checks.
6. Verify App Privacy answers against the shipped RevenueCat SDK and the final
   network behavior.

## App Store copy

ASO-ready English (U.S.) metadata and exact field counts are maintained in
[`docs/app-store-metadata.md`](docs/app-store-metadata.md).
