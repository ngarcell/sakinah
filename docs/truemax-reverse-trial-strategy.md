# TrueMax reverse-trial activation strategy

## The AHA moment

The AHA is the result of the user’s own successful scan: transparent facial
measurement ranges, capture confidence/methodology, and a practical action plan
that clearly follows from that baseline. The value becomes credible because it
is neither a sample screen nor a generic feature promise, and because the user
can inspect the limits of each estimate before being asked to pay.

## Production flow

```text
Entry
  “Check my baseline” + adult-only context
    |
    v
Necessary safeguards
  18+ confirmation -> face-data privacy + capture preparation
    |
    v
Minimum value path
  Checklist -> permission -> guided capture -> local analysis -> saved result
    |
    v
AHA
  Full baseline ranges + methodology + practical action plan
    |
    v
Paywall placement
  Result Done -> plans, with no review request or intermediate bridge
    |
    v
Activation loop
  Purchase/restore -> Home -> same baseline + this week’s guidance
  -> style tools/history -> next suggested check-in
```

## Why each step remains

- The separate “how it works” tour was removed because the shipping checklist
  and result methodology explain the product in context.
- Adult confirmation remains mandatory. Facial appearance analysis is a
  sensitive experience, and underage users receive supportive guidance rather
  than a score or scan workaround.
- Privacy and capture preparation remain immediately before the camera because
  informed consent and capture quality directly affect the value and safety of
  the result. They are one concise screen, not a general feature tour.
- There is no login, profile, survey, manual measurement entry, or fabricated
  preview. A camera denial, analysis failure, or save failure stays recoverable
  and never consumes the reverse trial.

## Paywall and conversion timing

The paywall can appear only after `TrueMaxScanRootView` has completed the real
capture-analysis-save path and the user has reviewed `TrueMaxResultDetailView`.
The reverse-trial consumed state is persisted at that boundary. An App Store
review sheet and the former second-tap handoff were removed because both break
the highest-intent moment without adding product value.

Unlock completes onboarding and lands on Home, not Scan. Home immediately
shows the exact saved baseline, its guidance, local-history entry, style tools,
and an appropriate next-check-in suggestion. This turns payment into continued
use of demonstrated value instead of forcing the user to repeat setup.

## Safety and truth constraints

- Results remain estimate ranges, never attractiveness ratings, diagnoses, or
  idealized-face comparisons.
- TrueDepth assistance is described only when available; Photo mode remains an
  explicit fallback.
- Face captures, landmarks, measurements, age signals, and guidance remain
  local and are excluded from anonymous telemetry and subscriber attributes.
- Underage, permission-denied, unavailable-camera, analysis-error, and local
  save-error paths remain explicit and recoverable.

## Activation measurement

Measure: welcome viewed -> adult gate passed -> scan CTA -> camera ready ->
capture accepted -> result saved -> AHA completed -> plans reached -> access
unlocked -> Home viewed -> second meaningful action. Only stable phases,
capture mode, confidence categories, counts, and error categories are sent;
facial inputs and result values are never analytics properties.
