# TrueMax — UI/UX Specification

**Status:** implementation source of truth · **Reviewed:** 19 July 2026

The 23 supplied reference PNGs are the visual source of truth. Do not invent
replacement screens or photo-realistic face transformations. The UI is a dark,
quiet, privacy-first instrument: TrueMax is shown in the app bar, navigation
titles stay compact, and content headings use semantic Dynamic Type styles.

## Visual system

- Dark mode is fixed throughout the app; Settings does not offer an appearance
  or theme switcher. Backgrounds, cards, borders, text, positive, neutral, and
  caution colors use the dark semantic tokens in `TrueMaxTheme.swift`.
- Primary actions use the contrast-safe `actionGradient`; decorative marks may
  use `primaryGradient`.
- Rounded cards, 44pt minimum touch targets, generous spacing, and no dense
  dashboard chrome.
- Fixed sizes are reserved for icons and illustrations. Text uses semantic
  `title2`, `title3`, `headline`, `body`, and metric display styles so large
  accessibility sizes remain usable.

## Screen map

### Onboarding

Welcome, how it works, age gate, privacy, and custom paywall. Every step has a
visible back/close affordance, clear camera/data language, and no account form.
The age gate is supportive and does not shame a decline or underage result.

### Home

Compact TrueMax lockup and “On-device” pill. First launch shows the baseline
card and “Start first scan.” Returning users see the latest result, New scan,
focus items, and quick tools.

### Capture

Checklist → capability-specific mode explanation → live camera. The camera
shows framing, face count, distance, luminance, and pose guidance. Photo mode
is an explicit fallback, never silently presented as 3D. Processing is local
and cancellable; saving happens only after analysis succeeds.

### Results

The reveal identifies `3D · TrueDepth` or `2D · Photo mode` and uses
“Depth-assisted estimate” or “Photo estimate.” Metric cards show a band (for
example `82–88`), a plain-language summary, methodology, and the statement
that the result is cosmetic—not clinical or an attractiveness score.

### Action plan and styles

The action plan ranks practical, low-effort guidance. The bundled intelligence
layer adds provenance cards that explain why a signal appeared and which
reviewed knowledge entry supports its guardrail. Style recommendations are
deterministic, derived from the latest local ranges, and use neutral
non-photorealistic overlays only.

### History and comparison

History is private and local. Users can filter 3D/Photo, select two scans,
swap older/newer ordering, inspect range changes, delete one scan, or delete
all data. VoiceOver describes comparison ordering and the Swap action.

### Settings

Theme switcher (Dark default), subscription status/Restore Purchases, legal
links, methodology, capture-quality explanation, and destructive local-data
deletion with confirmation and retry messaging.

## Paywall contract

Annual is selected by default; monthly is one tap away. Cards display live
localized StoreKit pricing, cadence, and introductory-offer details when
available. CTA behavior:

| Eligibility state | CTA | Disclosure |
|---|---|---|
| Checking | Checking plan… (disabled) | Waiting for StoreKit/RevenueCat |
| Eligible | Start Free Trial | Three days free, then the live selected price and cadence |
| Ineligible/no offer | Continue Pro — Annual/Monthly | Live price/cadence and auto-renewal terms |
| Unknown | Retry Plan Check (purchase disabled) | Eligibility could not be verified |

Terms, Privacy, Support, Restore Purchases, renewal timing, and Apple billing
disclosure remain visible without scrolling through a hidden menu.

## Accessibility and state copy

- All primary controls have VoiceOver labels and hints; range values include
  spoken units and lower/upper bounds.
- Dynamic Type accessibility sizes switch cards and plan choices to a single
  column. No critical text is clipped or conveyed by color alone.
- Permission denied: explain how to re-enable Camera in Settings.
- Save failure: report the database/file cleanup state and offer retry through
  Settings rather than claiming success.
- Underage/declined gate: explain that TrueMax is adult-only and provide a calm
  exit path.
