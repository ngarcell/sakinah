# Prompt 3 of 3 — Learn, Private Space, Subscriptions, Widgets & Polish

You are completing "Sakinah," a premium couples wellness iOS app for Muslim couples. Prompts 1 and 2 built: the project foundation, full design system (SakinahColor, SakinahFont, SakinahSpacing, all components and modifiers), SwiftData models, services (Auth, Pairing, CloudKit, Haptics, Content), complete onboarding flow, Today tab (daily prompt with 4-state reveal mechanic, du'a card, check-in), and Us tab (wellness garden with Canvas, weekly reflection, milestones/memories). All design tokens, components, and patterns from those prompts are available. Reference them consistently.

Now build the remaining features, implement subscriptions, add a home screen widget, and perform the final polish pass that elevates this from "good app" to "best-in-class."

**Tech constraints reminder:** iOS 17+, Swift 6, SwiftUI only, SwiftData, CloudKit, StoreKit 2, CryptoKit, WidgetKit — zero third-party dependencies.

---

## LEARN TAB — "Learn"

The Learn tab delivers weekly relationship wisdom. It should feel like a calm reading nook — unhurried, thoughtful, and rewarding.

### LearnView Layout

**Structure:** `ScrollView`, vertical stack

1. **Header:** "Learn" in `title1`. Below: "Wisdom for your journey together" in `bodySmall`, `textSecondary`

2. **This Week's Lesson Card** — hero element, full width

3. **Conversation Starters Section** — horizontal scroll of themed packs (premium)

4. **Past Lessons** — vertical list of completed lessons (collapsed by default, expandable)

---

### Weekly Lesson Card

**Card Container:** `SakinahCard(.elevated)`, full width

**Layout:**
- Top: illustration area — 180pt height, `primaryLight` background, centered geometric illustration. Use a simple SwiftUI `Path`-based Islamic geometric pattern unique to each lesson's category, rendered in `primary` at 20% opacity with one accent element in `accent` color.
- Below illustration:
  - Category pill: `SakinahBadge` ("Communication", "Conflict Resolution", "Spiritual Growth", etc.)
  - Lesson title in `title2`: e.g., "The Art of Listening with Your Heart"
  - "5 min read" in `caption`, `textTertiary`, with `clock` SF Symbol
  - Lesson body preview: first 2 lines of content in `body`, `textSecondary`, truncated
  - "Read Lesson" `SakinahButton(.primary)`, full width

**Lesson Detail View** (pushed via `NavigationLink` or `.fullScreenCover` with custom transition):
- Top: same illustration, larger (240pt), parallax scroll effect (moves at 0.5x scroll speed using `GeometryReader` + `.offset`)
- Back button: custom `chevron.left` in `primary` color circle
- Content sections, each rendered as:
  - Section header in `title3`
  - Body text in `body` with generous line height (24pt)
  - Pull quotes: indented with `accent` left border (3pt), `headline` weight, `primary` color
  - If section includes a du'a/hadith reference: styled in the same format as the Daily Du'a card (Arabic + transliteration + translation)
- Bottom "Try This" action card:
  - `SakinahCard` with `accentLight` background
  - "Try This Together 💡" in `headline`
  - Action description in `body`
  - "Mark as Done" `SakinahButton(.secondary)` — saves completion to SwiftData
  - Haptic `success` on mark complete
- Below action: "Share Lesson" `SakinahButton(.ghost)` → share sheet with formatted lesson summary

### Lesson Content Model
```json
{
  "id": "lesson_001",
  "title": "The Art of Listening with Your Heart",
  "category": "communication",
  "readTimeMinutes": 5,
  "sections": [
    {
      "type": "text",
      "heading": "Why Listening Is an Act of Love",
      "body": "The Prophet ﷺ was known as the best listener among his companions..."
    },
    {
      "type": "hadith",
      "arabic": "...",
      "transliteration": "...",
      "translation": "...",
      "source": "Sahih Bukhari"
    },
    {
      "type": "text",
      "heading": "Three Levels of Listening",
      "body": "..."
    }
  ],
  "tryThis": {
    "description": "Tonight, put your phones away for 15 minutes. Ask your partner 'What's been on your mind today?' and just listen. Don't problem-solve. Just be present.",
    "category": "communication"
  },
  "isPremium": false
}
```

---

### Conversation Starter Packs (Premium)

**Section Header:** "Conversation Starters" in `title3` + `lock.fill` SF Symbol if user is on free tier, `crown.fill` in `accent` if premium

**Horizontal Scroll:** `.scrollTargetBehavior(.viewAligned)`, 12pt spacing

**Pack Cards:** 200pt wide × 260pt tall `SakinahCard`
- Top 50%: themed gradient background (each pack has a unique gradient pair)
- Icon: relevant SF Symbol in white, 40pt, centered in gradient area
- Pack name in `headline`: "Before Baby 👶", "Money & Us 💰", "Our Dreams ✨", "Difficult Conversations 🌊", "Intimacy & Closeness 🤍"
- "20 prompts" in `caption`, `textSecondary`
- If locked (free tier): frosted glass overlay with `lock.fill` and "Unlock with Premium" label

**Pack Detail View** (sheet, `.large` detent):
- Pack title and description at top
- List of 20 prompts, each in a minimal `SakinahCard`:
  - Prompt text in `body`
  - Tap to expand: shows full prompt + "Use Tonight" button that saves it as a custom daily prompt override
- If free tier: first 3 prompts visible, rest blurred with "Upgrade to Premium" CTA

**Gradient Pairs per Pack:**

| Pack | Start Color | End Color |
|------|-----------|----------|
| Before Baby | #FDE68A | #F59E0B |
| Money & Us | #34D399 | #059669 |
| Our Dreams | #818CF8 | #6366F1 |
| Difficult Conversations | #67E8F9 | #0891B2 |
| Intimacy & Closeness | #FDA4AF | #E11D48 |

---

## OURS TAB — "Ours" (Private Space)

Everything in this tab is end-to-end encrypted. This is the couple's sacred space.

### OursView Layout

**Top:** "Ours 🔒" in `title1`. Below: "Your private space, encrypted end-to-end" in `caption`, `textTertiary`, with a small `lock.shield.fill` icon

**Navigation:** 4 sections displayed as a 2×2 grid of tappable cards, each `SakinahCard` with:
- Icon (SF Symbol, 32pt, `primary`)
- Title in `headline`
- Subtitle in `caption`, `textSecondary`
- Tap navigates to detail view via `NavigationLink`

| Card | Icon | Title | Subtitle |
|------|------|-------|----------|
| Journal | `book.fill` | Shared Journal | "Write together" |
| Letters | `envelope.fill` | Love Letters | "Send future surprises" |
| Goals | `target` | Shared Goals | "[X] active goals" |
| Wishes | `gift.fill` | Wishlists | "Hint, hint... 😉" |

---

### Shared Journal

**Layout:** Reverse-chronological feed of journal entries

**Entry Card:** `SakinahCard`, full width
- Top-left: author name in `captionBold`, author avatar (initials circle, 24pt)
- Top-right: date in `caption`, `textTertiary`
- Body: entry text in `body`, max 6 lines with "Read more" if longer
- Bottom-left: visibility badge — `eye.fill` "Shared" or `eye.slash.fill` "Private" in `caption`
- Entries from partner use `accentLight` background tint; user's entries use `surface`

**Compose:** Floating "+" button (bottom-right, 56pt circle, `primary` fill, white `plus` icon, `medium` shadow)
- Opens `.sheet` with `large` detent
- `TextEditor` with placeholder "What's on your heart today?"
- Toggle: "Share with [partner name]" (default ON)
- Date auto-set to now
- "Save" `SakinahButton(.primary)`

**Encryption:** All journal entry content encrypted with CryptoKit before CloudKit write. Decrypted on-device only.

---

### Love Letters

**Concept:** Write a letter now, schedule it to be delivered later (partner's birthday, anniversary, "just because" on a random Tuesday).

**List View:** Cards showing scheduled and delivered letters
- Scheduled: `SakinahCard` with `accentLight` background, envelope icon sealed, "Delivers on [date]" in `bodySmall`, option to edit/delete
- Delivered: `SakinahCard`, envelope icon open, date delivered, partner can tap to read
- Received (from partner): `SakinahCard` with `primaryLight` background, special "💌 From [partner name]" header

**Compose View:** `.fullScreenCover` with custom transition (slide up + fade)
- "Write a Love Letter" in `title2`
- "To: [partner name]" in `headline`, `accent`
- `TextEditor` styled as lined paper: `backgroundSecondary` fill with horizontal rule lines every 28pt using an overlay `Path`
- "Deliver on:" date picker (minimum: tomorrow)
- Optional: "Add a title" `SakinahTextField`
- "Seal & Schedule 💌" `SakinahButton(.primary)` — save with haptic `success`, envelope seal animation (envelope flap closes)

**Delivery:** `NotificationService` schedules local notification for delivery date. On partner's next app open after delivery date, letter appears with a special reveal animation (envelope slides in from bottom, flap opens, letter slides up).

---

### Shared Goals

**List View:** Active goals at top, completed goals in collapsible section below

**Goal Card:** `SakinahCard`, full width
- Goal title in `headline`: e.g., "Pray Fajr together 20 times this month"
- Progress bar: rounded, 8pt tall, `primaryLight` track, `primary` fill, animated on change
- "[12/20] — 60%" in `bodySmall`, `textSecondary`
- Deadline: "Due [date]" in `caption`
- Quick action: "+" circle button (28pt, `primary` outline) to increment progress. Haptic `tap` on press, `success` when goal completed.
- On goal completion: confetti-like particle burst (reuse the Canvas particle system from prompt reveal), card background briefly flashes `accent` at 10%

**Add Goal Sheet:** `.sheet`, `medium` detent
- Title `SakinahTextField`
- Target number picker (stepper, 1–100)
- Deadline date picker
- Category selector: "Spiritual 🤲", "Quality Time 💑", "Health 🌿", "Financial 💰", "Other ✨"
- "Create Goal" `SakinahButton(.primary)`

---

### Wishlists

**Layout:** Two columns, side-by-side
- Left column: "My Wishes" (user's list, editable) — partner sees this
- Right column: "[Partner name]'s Wishes" (partner's list, read-only) — gift inspiration

**Wish Item:** Minimal row
- Wish text in `body`, single line
- Swipe-to-delete on own items
- Tap to expand: optional note, optional link (URL detection)

**Add Wish:** "+" button at bottom of "My Wishes" column, inline text field expansion

---

## SETTINGS

### SettingsView Layout
`List` with `.insetGrouped` style, custom section headers

**Section 1: Profile**
- Row: user avatar (initials circle, 48pt) + name + email from Apple ID
- "Paired with [partner name]" in `bodySmall`, `textSecondary`
- "Unlink Partner" destructive button (`.red` foreground) with two-step confirmation alert

**Section 2: Notifications**
- Toggle: Daily prompt notification (default ON)
- Time picker: "Prompt time" (default 9:00 AM)
- Toggle: Partner activity notifications (default ON)
- Toggle: Weekly reflection reminder (default ON)
- Day picker: Reflection day (default Friday)
- Toggle: Milestone celebrations (default ON)

**Section 3: Subscription**
- Current tier display: "Free" or "Sakinah Premium ✨"
- If free: "Upgrade to Premium" `SakinahButton(.primary)`, triggers paywall
- If premium: "Manage Subscription" → opens `SubscriptionStoreView` or `manageSubscriptionsSheet`
- Subscription benefits list (if free): 4-5 bullet points of premium features

**Section 4: Preferences**
- Du'a language: picker (Arabic + English / Arabic + Transliteration / All Three)
- Calendar: Toggle Hijri date display
- Appearance: System / Light / Dark picker
- Haptic feedback: Toggle

**Section 5: Privacy & Data**
- "Your data is encrypted end-to-end" banner with `lock.shield.fill`
- "Export My Data" → generates JSON export
- "Delete All Data" → destructive, two-step confirmation, calls `AuthService.deleteAccount()`
- "Privacy Policy" and "Terms of Service" → `Link` to URLs

**Section 6: About**
- App version + build number
- "Made with 🤍 for the ummah"
- "Rate Sakinah" → `requestReview()` environment action
- "Share Sakinah" → share sheet
- "Contact Support" → `mailto:` link

---

## SUBSCRIPTIONS (StoreKit 2)

### Implementation: SubscriptionService.swift

```swift
@Observable
final class SubscriptionService {
    var subscriptionStatus: SubscriptionStatus = .notSubscribed
    var availableProducts: [Product] = []
    
    // Product IDs
    static let monthlyID = "com.sakinah.premium.monthly"
    static let annualID = "com.sakinah.premium.annual"
    static let lifetimeID = "com.sakinah.premium.lifetime"
    
    func loadProducts() async
    func purchase(_ product: Product) async throws -> Transaction
    func checkEntitlement() async
    func listenForTransactions() -> Task<Void, Error>  // Transaction.updates listener
    func restorePurchases() async
}
```

- Use `Product.products(for:)` to load
- Use `Transaction.currentEntitlements` to verify on launch
- Background listener via `Transaction.updates` for real-time status changes
- Store subscription tier in `AppState` and `User` SwiftData model

### Paywall Design: SakinahPaywallView

**Trigger points (soft paywall — never blocks core features):**
1. Tapping a locked Conversation Starter pack
2. Tapping "Trends" in the garden plant detail sheet
3. After 7 days of daily engagement, shown once as a `.sheet`
4. Settings → "Upgrade to Premium"

**Paywall Layout:** `.sheet` with `.large` detent, non-dismissable drag (`.interactiveDismissDisabled(false)` — user CAN dismiss, but with slight resistance via `.presentationDragIndicator(.visible)`)

**Visual Structure:**
1. Top: "Unlock Sakinah Premium ✨" in `title1`, centered
2. Illustration: the wellness garden at full bloom, all 5 plants at level 5 with sparkles (static image or lightweight Canvas render)
3. Benefits list: 4 rows, each with `accent` checkmark circle + benefit text in `body`:
   - "Deeper conversations with themed prompt packs"
   - "Relationship trend insights over time"
   - "Scheduled love letters & shared goals"
   - "Early access to new features"
4. Plan selection: 3 cards in a horizontal row:

| Plan | Price | Subtitle | Visual |
|------|-------|----------|--------|
| Monthly | $9.99/mo | "Flexible" | `SakinahCard`, standard border |
| **Annual** | $49.99/yr | "Best Value — Save 58%" | `SakinahCard`, `accent` border (3pt), `SakinahBadge` "BEST VALUE" overlapping top-right corner, default selected |
| Lifetime | $129.99 | "Pay once, forever" | `SakinahCard`, standard border |

- Selected plan: `accent` border, `accentLight` background, subtle `glow` shadow in `accent`
- Unselected: `surface` background, `divider` border

5. "Start 7-Day Free Trial" `SakinahButton(.primary)`, full width (for annual plan). For monthly: "Subscribe". For lifetime: "Purchase"
   - Below button: "Then $49.99/year. Cancel anytime." in `caption`, `textTertiary`

6. Bottom links: "Restore Purchases" and "Terms • Privacy" in `caption`, `textTertiary`, tappable

**After successful purchase:** dismiss paywall, show a brief celebration overlay (gold particle burst + "Welcome to Premium ✨" text that fades in and out over 2s), haptic `celebration`

---

## WIDGETKIT — Home Screen Widget

### Widget: SakinahDailyWidget

**Widget Configuration:**
- `StaticConfiguration` (no user config needed)
- Supported families: `.systemSmall`, `.systemMedium`
- Widget bundle registered in `NoorApp.swift`

**Small Widget (systemSmall):**
- Background: `background` color
- Top-left: "sakinah" wordmark in `captionBold`, `primary`
- Center: today's prompt text in `headline` style, max 3 lines, `textPrimary`
- Bottom: prompt category badge, small
- Deep link: opens app to Today tab, daily prompt

**Medium Widget (systemMedium):**
- Left half: daily prompt (same as small, but more text space — 4 lines)
- Right half: du'a of the day — Arabic text in `arabic` font (18pt), translation below in `caption`
- Divider between halves: 1pt vertical line, `divider` color
- Deep link left: opens to daily prompt. Deep link right: opens to du'a.

**Timeline Provider:**
- `TimelineProvider` generates entries at midnight daily
- Reads current day's prompt and du'a from bundled JSON (same `ContentService` logic)
- `.atEnd` reload policy

**App Intent for deep linking:**
- Define `OpenSakinahIntent` with `destination` parameter (`.prompt`, `.dua`)
- Handle in `SakinahApp.swift` `onOpenURL` or `.handlesExternalEvents`

---

## FINAL POLISH CHECKLIST

Apply these across the entire app before considering it complete:

### Accessibility
- Every interactive element has an `.accessibilityLabel` and `.accessibilityHint`
- Garden plants have descriptive labels: "Communication plant, thriving at level 4"
- Prompt reveal uses `.accessibilityAddTraits(.updatesFrequently)` during animation
- Support Dynamic Type at all sizes (test with largest accessibility size)
- All color contrasts meet WCAG AA (4.5:1 for body text, 3:1 for large text)
- `.accessibilityAction` on the check-in mood selector for VoiceOver: announce mood name on focus
- Reduce Motion: replace all spring/particle animations with simple opacity fades when `UIAccessibility.isReduceMotionEnabled` is true

### Performance
- `LazyVStack` for any list longer than ~10 items
- Garden `Canvas` rendering: cache plant paths, only redraw on state change or ambient animation tick
- Images in memories: `AsyncImage` with `.resizable()` and `.aspectRatio(contentMode: .fill)`, downsampled thumbnails for list view
- CloudKit fetches: debounce with `Task` cancellation to avoid redundant calls on rapid navigation
- Prompt content: pre-loaded on app launch, cached in SwiftData. Never block the main thread.

### Edge Cases
- **Solo mode** (partner hasn't joined yet): Today tab works with prompts (user can answer, reveal is skipped — response is saved). Du'a and check-in work independently. Garden shows only user's engagement. Weekly reflection works solo. Learn tab fully functional.
- **Offline mode**: All core features work offline via SwiftData local cache. CloudKit syncs when reconnected. Show subtle "Offline — changes will sync when connected" banner (1 line, `warning` background, `caption` text) at top of TodayView when `NWPathMonitor` detects no connectivity.
- **New day rollover**: `ContentService` checks date on `scenePhase` change to `.active`. If date changed since last check, refresh daily prompt and du'a.
- **Subscription expiry**: When subscription lapses, premium features gracefully lock (blur + lock icon overlay) without data loss. User retains all their data, just can't access premium features.
- **Account deletion**: Full cascade delete of all SwiftData objects, CloudKit records, and Keychain items. Confirmation flow: first alert → type "DELETE" → second confirmation → execute.

### App Store Readiness
- App icon: the word "sakinah" stylized in the warm gold `accent` color on a deep teal `primary` background. Clean, minimal, modern Arabic-inspired letterforms. Create all required sizes in Assets.xcassets.
- Launch screen: solid `background` color with centered "sakinah" wordmark. No storyboard — use `Info.plist` background color key.
- `Info.plist` entries:
  - `NSCameraUsageDescription`: "Sakinah uses your camera to capture memories with your partner"
  - `NSPhotoLibraryUsageDescription`: "Sakinah accesses your photos to save shared memories"
  - `NSUserNotificationsUsageDescription`: handled by notification permission request
- Privacy Nutrition Label: prepare accurate data for App Store Connect submission

### Interaction Polish Details
- Tab bar: custom-styled with `primary` tint for selected tab, `textTertiary` for unselected. Icons: `sun.max.fill` (Today), `heart.fill` (Us), `book.fill` (Learn), `lock.fill` (Ours). Selected icon has a subtle `glow` shadow in `primary`.
- Navigation transitions: default push transitions, but the onboarding-to-main transition should be a custom matched geometry effect or a zoom transition.
- Pull-to-refresh on TodayView and UsView: custom styled with `ProgressView` in `primary` tint.
- Empty states: every list/collection (journal, goals, memories, wishlists) must have a beautiful empty state using `SakinahEmptyState` component — relevant illustration/icon, warm copy, and a clear CTA.
- Keyboard handling: all text inputs scroll into view properly. Dismiss keyboard on tap outside. "Done" toolbar button above keyboard for `TextEditor`.
- Sheet presentations: all use `.presentationCornerRadius(20)` and `.presentationBackground(.ultraThinMaterial)` for the dimming layer behind the sheet.

---

## What to Deliver in This Prompt
1. Complete `LearnView` with weekly lesson card, lesson detail view (parallax, structured content renderer, "Try This" action), and conversation starter packs (horizontal scroll, pack detail sheet, free/premium gating)
2. Complete `OursView` with all 4 sub-features: shared journal (with compose), love letters (with scheduled delivery), shared goals (with progress tracking and completion animation), and wishlists
3. `EncryptionService` implementation using CryptoKit for E2EE on all Private Space content
4. `SubscriptionService` full StoreKit 2 implementation with transaction listener
5. `SakinahPaywallView` — complete paywall with plan selection and purchase flow
6. `SettingsView` — complete with all sections, all toggles functional
7. `SakinahDailyWidget` — WidgetKit implementation for small and medium widgets
8. All final polish: accessibility labels, reduce motion support, offline banner, empty states, edge case handling, keyboard management
9. Full navigation wiring: `ContentView` routes auth state, `MainTabView` has all 4 tabs connected to real views

This is the final prompt. When you're done, every screen should be implemented, every animation should be smooth, every edge case should be handled, and the app should feel like it was built by a team of 10 over 6 months — not generated in a day. Make it extraordinary.
