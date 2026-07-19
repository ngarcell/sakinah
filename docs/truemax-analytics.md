# TrueMax analytics contract

TrueMax uses the centralized `TrueMaxAnalytics` service with anonymous
PostHog events. RevenueCat remains the only purchase and entitlement authority.

## Coverage

| Area | Events |
|---|---|
| Lifecycle and navigation | app opened, screen viewed, tab selected |
| Onboarding | age selection, scan CTA, step progression, completion, reverse-trial consumption |
| Scan | camera request/block, preparation, phase changes, capture, result available, AHA completion, failures |
| Paywall | presented/dismissed, load failures, plan selection, CTA taps, eligibility, purchase outcomes, restore outcomes, unlocked |
| Product surfaces | home, main tabs, history, settings, result, style library, color analysis |
| Conversion | App Store review prompt requested immediately before the first-value paywall |

Properties are limited to non-sensitive enums, stable IDs, counts, confidence
categories, capture mode, placement, source, and error categories. Facial
images, measurements, landmarks, style selections, and free-form content are
never sent. PostHog interaction and rage-click autocapture are enabled for
friction diagnostics; session replay is not enabled for camera surfaces.
