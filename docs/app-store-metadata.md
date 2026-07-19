# TrueMax App Store Metadata

Updated: July 19, 2026

Locale: English (U.S.)

This copy is conversion-focused without claiming medical accuracy, an
attractiveness rating, cloud-free subscription processing, or a free trial that
StoreKit has not confirmed. Facial captures and results stay on device;
subscription purchases and entitlement checks are handled by Apple and
RevenueCat.

Apple's current limits are 30 characters for the name, 30 for the subtitle, 170
for Promotional Text, 4,000 for Description, 100 UTF-8 bytes for Keywords, and
4,000 for What's New.

References:

- [App Store Connect platform-version fields](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [Creating your App Store product page](https://developer.apple.com/app-store/product-page/)
- [Apple subscription presentation requirements](https://developer.apple.com/app-store/subscriptions/)

## Recommended name

```text
TrueMax: Face & Style
```

Count: 21/30 characters.

## Recommended subtitle

```text
Private On-Device Analysis
```

Count: 26/30 characters.

## Promotional Text

```text
Private face and style insights, processed on your iPhone. Explore measurement ranges, understand the method, and build a practical grooming plan—without an account.
```

Count: 165/170 characters.

Promotional Text is designed for conversion and is not treated as a keyword
field.

## Description

```text
TrueMax helps adults understand supported facial measurements and build a practical grooming and style plan—without uploading their face.

CAPTURE WITH CLEAR GUIDANCE
Use live on-device face, framing, distance, and lighting guidance to take a consistent scan. On compatible devices, transient TrueDepth geometry refines estimate bands; other supported iPhones use a clearly labeled photo mode with wider bands.

HONEST, EXPLAINED RESULTS
• See measurement ranges instead of a fake-precise attractiveness score
• Review plain-language explanations for symmetry, proportions, facial thirds, and other supported geometry
• Expand each result to understand the method and why uncertainty exists
• Retake when you choose, with a calm reminder if your previous scan was recent

PRACTICAL GUIDANCE
Receive an on-device plan focused on grooming, basic skincare, hairstyle, clothing color, posture, and photo presentation. Guidance stays within those everyday topics and never includes diet, supplements, medication, or body-modification advice.

PRIVATE BY DESIGN
Your face captures, facial geometry, results, coaching plan, and history remain locally on your iPhone. They are not uploaded to TrueMax, and no TrueMax account is required. Subscription purchases and entitlement checks are processed through Apple and RevenueCat; facial images and measurements are never attached to that purchase data.

LOCAL PROGRESS
Keep a private timeline of past scans and compare measurement ranges over time. Delete an individual result or erase all locally stored data whenever you choose.

RESPONSIBLE BY DESIGN
TrueMax has no public face ratings, leaderboards, comparison feed, or generated “ideal” version of you. Results use neutral language and are intended to inform—not define—how you see yourself.

TrueMax is for adults 18 and older. It provides appearance, grooming, and style information only. It does not provide medical, dermatological, or psychological advice.

SUBSCRIPTION
An active auto-renewing subscription is required to use TrueMax. Monthly and annual plans are available, with annual selected by default. If an introductory free trial is available and you are eligible, its duration and renewal price are shown before purchase. Payment is charged to your Apple Account. Your subscription renews automatically unless canceled. You can manage or cancel it in your Apple Account settings and restore eligible purchases in the app.

Privacy Policy: https://socialreporthq.com/sakinah/privacy
Terms of Use: https://socialreporthq.com/sakinah/terms
Support: https://socialreporthq.com/sakinah/support
```

Count: 2,601/4,000 characters.

## Keywords

This keyword set assumes the recommended name and subtitle above are used. It
therefore does not waste bytes repeating `TrueMax`, `face`, `style`, `private`,
`on-device`, or `analysis`.

```text
symmetry,grooming,skincare,hair,appearance,proportion,jawline,color,coach,selfie,confidence,men,tips
```

Count: exactly 100/100 UTF-8 bytes.

Do not add competitor names, trademarks, category names, irrelevant terms,
duplicate words, or plurals of included singular terms.

## What's New

```text
Welcome to TrueMax—a completely new, privacy-first face and style experience for adults.

• Guided camera capture with lighting, framing, and distance feedback
• Depth-assisted estimate bands on compatible devices and clearly labeled photo-mode estimates elsewhere
• Supported facial measurements shown as honest ranges with methodology explanations
• On-device grooming and style guidance within clear safety boundaries
• A private local history with range-based comparisons and full deletion controls
• Adult age gating, neutral result language, and a calm rescan reminder
• No account, social rating, public leaderboard, or generated “ideal” face
• Custom monthly and annual subscription choices, with annual selected by default
• Restore Purchases and subscription management support

Facial captures, measurements, coaching, and history remain on your device. This release also includes VoiceOver, Dynamic Type, Reduce Motion, and layout support across iPhone and iPad.
```

Count: 976/4,000 characters.

## App Store Connect coordination

Before submission:

1. Set the App Store name/subtitle to the recommended values or recalculate the
   keyword field to remove any repeated terms.
2. Use Health & Fitness as the primary category only if the final binary and
   review positioning support that choice.
3. Set the age rating to the highest applicable App Store bracket and clearly
   state that TrueMax itself is for adults 18 and older.
4. Use the live localized monthly and annual prices. Do not place fixed prices
   in the description.
5. Show trial language only for an actual configured introductory offer and
   only to an eligible customer.
6. Ensure screenshots show the shipping UI, range-based results, 2D/3D
   disclosure, local privacy, and the custom two-plan paywall.
7. Confirm the Privacy Policy, Terms, and Support URLs are live and describe
   TrueMax rather than Sakinah.
8. Complete App Privacy answers from the actual RevenueCat SDK privacy manifest
   and observed runtime behavior; do not assume “Data Not Collected.”
