# TrueMax no-analytics contract

TrueMax does not initialize an analytics SDK or transmit product events.
`TrueMaxAnalytics` remains as a no-op compatibility facade so existing call
sites—including protected commercial surfaces—do not require behavioral
changes. RevenueCat remains the only purchase and entitlement authority.

## Local instrumentation map

The retained calls document the states a future, expressly disclosed
instrumentation system would need to cover:

| Area | Local call sites |
|---|---|
| Lifecycle and navigation | app opened, screen viewed, tab selected |
| Onboarding | age-choice interaction without the selected age range, scan CTA, step progression, completion, reverse-trial consumption |
| Scan | camera request/block, preparation, phase changes, capture, result available, AHA completion, failures |
| Paywall | presented/dismissed, load failures, plan selection, CTA taps, eligibility, purchase outcomes, restore outcomes, unlocked |
| Product surfaces | home, main tabs, history, settings, result, style library, color analysis |
| Conversion | AHA result completed, reverse trial consumed, plan surface reached, and access unlocked |

None of these calls configure an SDK, persist event data, or send network
requests. Re-enabling analytics requires a reviewed product decision plus
matching updates to the public privacy policy, App Store privacy answers,
privacy manifest assessment, this contract, and user-facing copy.
