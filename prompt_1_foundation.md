# Prompt 1 of 3 — Foundation: Project Setup, Design System, Architecture & Onboarding

You are a principal iOS engineer and product designer building "Sakinah" — a premium couples wellness app for Muslim couples. You write production-grade Swift 6 / SwiftUI code with obsessive attention to visual polish, interaction design, and native platform integration. Every screen you build should feel like it belongs in an Apple keynote demo.

## Project Requirements

Create a new Xcode project called `Sakinah` with the following setup:
- **iOS 17.0+** deployment target, iPhone only (iPad can adapt later)
- **Swift 6** with strict concurrency checking enabled
- **SwiftUI** exclusively — no UIKit unless absolutely necessary for a specific interaction
- **SwiftData** for local persistence
- **CloudKit** (private database) for couple sync
- **StoreKit 2** for subscriptions (implement later, but define the service protocol now)
- **CryptoKit** for end-to-end encryption of private content
- **Zero third-party dependencies** — everything uses native Apple frameworks

## Architecture

Use **MVVM with Repository pattern** and Swift Concurrency throughout:

```
Sakinah/
├── App/
│   ├── SakinahApp.swift                 # @main entry, scene setup
│   ├── AppState.swift                   # Global observable state (auth, pairing, subscription tier)
│   └── ContentView.swift                # Root view: branching between Onboarding ↔ MainTabView
├── DesignSystem/
│   ├── Theme.swift                      # All colors, typography, spacing, radii, shadows
│   ├── SakinahFont.swift                # Type scale definitions
│   ├── SakinahColor.swift               # Semantic color tokens
│   ├── SakinahSpacing.swift             # Spacing scale
│   ├── Components/
│   │   ├── SakinahButton.swift          # Primary, secondary, ghost button styles
│   │   ├── SakinahCard.swift            # Elevated card container
│   │   ├── SakinahTextField.swift       # Styled text input
│   │   ├── SakinahBadge.swift           # Small status/tag badges
│   │   ├── SakinahEmptyState.swift      # Reusable empty state view
│   │   └── SakinahLoadingView.swift     # Branded loading indicator
│   └── Modifiers/
│       ├── ShimmerModifier.swift         # Subtle shimmer effect for loading states
│       ├── PressModifier.swift           # Scale-down press feedback
│       └── GlowModifier.swift           # Soft glow for accent elements
├── Features/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   ├── OnboardingViewModel.swift
│   │   ├── WelcomeScreen.swift
│   │   ├── SignInScreen.swift
│   │   ├── InvitePartnerScreen.swift
│   │   ├── WaitingForPartnerScreen.swift
│   │   ├── CoupleSetupScreen.swift
│   │   └── FirstPromptScreen.swift
│   ├── Today/                            # (Prompt 2)
│   ├── Us/                               # (Prompt 2)
│   ├── Learn/                            # (Prompt 3)
│   ├── Ours/                             # (Prompt 3)
│   └── Settings/                         # (Prompt 3)
├── Models/
│   ├── User.swift                        # SwiftData @Model
│   ├── Couple.swift                      # SwiftData @Model
│   ├── DailyPrompt.swift
│   ├── PromptResponse.swift
│   ├── CheckIn.swift
│   ├── Dua.swift
│   ├── WeeklyReflection.swift
│   ├── Lesson.swift
│   ├── JournalEntry.swift
│   ├── SharedGoal.swift
│   └── Milestone.swift
├── Services/
│   ├── AuthService.swift                 # Sign in with Apple
│   ├── CloudKitService.swift             # CloudKit sync engine
│   ├── PairingService.swift              # Partner invite code generation + linking
│   ├── NotificationService.swift         # Local + push notification scheduling
│   ├── EncryptionService.swift           # CryptoKit E2EE wrapper
│   ├── SubscriptionService.swift         # StoreKit 2 (protocol now, implementation in Prompt 3)
│   └── ContentService.swift              # Prompt/Dua/Lesson content pipeline
├── Utilities/
│   ├── HapticEngine.swift                # Centralized haptic feedback
│   ├── DateFormatting.swift              # Hijri + Gregorian helpers
│   └── Constants.swift
└── Resources/
    ├── Assets.xcassets                    # Colors, images, app icon
    ├── Prompts.json                      # Bundled prompt content (365+ prompts)
    ├── Duas.json                         # Bundled du'a content (120+ du'as)
    └── Localizable.strings
```

## Design System — Implement Every Token

### Colors (SakinahColor.swift)
Define as `Color` extensions with BOTH light and dark mode variants using `Assets.xcassets` color sets:

| Token Name | Light Mode | Dark Mode | Usage |
|-----------|-----------|----------|-------|
| `primary` | #0D5C63 (Deep Teal) | #14919B | Primary actions, headers, active states |
| `primaryLight` | #E8F5F6 | #0D3D42 | Primary tinted backgrounds |
| `accent` | #C4923A (Warm Gold) | #D4A84B | Highlights, badges, special moments |
| `accentLight` | #FFF3E0 | #3D2E14 | Accent tinted backgrounds |
| `surface` | #FFFFFF | #1A1A2E | Card backgrounds |
| `surfaceElevated` | #FFFFFF, shadow | #222244 | Elevated cards |
| `background` | #FDF6EC (Soft Cream) | #0A0A1A (Deep Night) | Page backgrounds |
| `backgroundSecondary` | #F5EFE4 | #141428 | Secondary backgrounds |
| `textPrimary` | #1A1A2E | #F2F0ED | Body text |
| `textSecondary` | #6B7280 | #9CA3AF | Supporting text |
| `textTertiary` | #9CA3AF | #6B7280 | Hints, placeholders |
| `success` | #2D8A4E | #34D399 | Positive states, growth |
| `warning` | #D97706 | #FBBF24 | Attention needed |
| `error` | #DC2626 | #F87171 | Errors, destructive actions |
| `divider` | #E5E7EB (8% opacity) | #374151 (12% opacity) | Separators |

### Typography (SakinahFont.swift)
Use SF Pro with a clear hierarchy. Define as ViewModifier or Text extension:

| Style Name | Font | Size | Weight | Line Height | Letter Spacing | Usage |
|-----------|------|------|--------|-------------|---------------|-------|
| `heroTitle` | SF Pro Display | 34 | Bold | 41 | -0.4 | Welcome screen, major headers |
| `title1` | SF Pro Display | 28 | Bold | 34 | -0.3 | Section titles |
| `title2` | SF Pro Display | 22 | Semibold | 28 | -0.2 | Card titles |
| `title3` | SF Pro Text | 20 | Semibold | 25 | 0 | Subsection headers |
| `headline` | SF Pro Text | 17 | Semibold | 22 | 0 | Emphasized body |
| `body` | SF Pro Text | 17 | Regular | 24 | 0 | Primary body text |
| `bodySmall` | SF Pro Text | 15 | Regular | 21 | 0 | Secondary body text |
| `caption` | SF Pro Text | 13 | Regular | 18 | 0.1 | Metadata, timestamps |
| `captionBold` | SF Pro Text | 13 | Semibold | 18 | 0.1 | Labels, tags |
| `arabic` | System Arabic (or bundled Amiri) | 24 | Regular | 36 | 0 | Du'a Arabic text |
| `arabicSmall` | System Arabic | 18 | Regular | 28 | 0 | Inline Arabic |

### Spacing (SakinahSpacing.swift)
8-point grid system:

| Token | Value |
|-------|-------|
| `xxs` | 2 |
| `xs` | 4 |
| `sm` | 8 |
| `md` | 12 |
| `base` | 16 |
| `lg` | 20 |
| `xl` | 24 |
| `xxl` | 32 |
| `xxxl` | 40 |
| `jumbo` | 48 |
| `mega` | 64 |

### Corner Radii
| Token | Value | Usage |
|-------|-------|-------|
| `small` | 8 | Buttons, badges |
| `medium` | 12 | Cards, inputs |
| `large` | 16 | Modal sheets |
| `xl` | 24 | Featured cards |
| `full` | .infinity | Circular avatars, pills |

### Shadows
| Token | Color | X | Y | Blur | Usage |
|-------|-------|---|---|------|-------|
| `subtle` | black 4% | 0 | 1 | 3 | Resting cards |
| `medium` | black 8% | 0 | 4 | 12 | Elevated cards, buttons |
| `strong` | black 12% | 0 | 8 | 24 | Modals, floating elements |
| `glow` | primary 20% | 0 | 0 | 20 | Active/focused states |

### Animation Curves
Define as named `Animation` constants:
- `sakinahSpring`: `.spring(response: 0.45, dampingFraction: 0.8)` — default interaction spring
- `sakinahGentle`: `.spring(response: 0.6, dampingFraction: 0.85)` — gentle transitions
- `sakinahBounce`: `.spring(response: 0.35, dampingFraction: 0.6)` — playful moments (reveals, celebrations)
- `sakinahSlow`: `.easeInOut(duration: 0.8)` — garden growth, ambient transitions

### Haptic Patterns (HapticEngine.swift)
Centralized haptic manager using `UIImpactFeedbackGenerator` and `UINotificationFeedbackGenerator`:
- `tap`: `.light` impact — button taps
- `select`: `.medium` impact — selecting options
- `success`: `.success` notification — prompt reveal, milestone
- `celebration`: custom pattern — `.heavy` + delay + `.medium` + delay + `.light` — milestone celebrations
- `error`: `.error` notification — validation errors

## Component Specifications

### SakinahButton
Three variants: `.primary`, `.secondary`, `.ghost`
- Primary: filled with `primary` color, white text, `medium` shadow, 50pt height, `small` radius
- Secondary: `primaryLight` background, `primary` text, no shadow, 50pt height
- Ghost: transparent, `primary` text, no shadow, 44pt height
- ALL variants: `PressModifier` on tap (scale to 0.97, duration 0.15), haptic `tap` on press
- Loading state: replace label with `ProgressView()` centered, button disabled
- Full-width by default, support `.fixedWidth` modifier for inline use

### SakinahCard
- Background: `surface` color
- Corner radius: `medium` (12)
- Shadow: `subtle` default, `medium` on press
- Padding: `base` (16) internal
- Support for `.elevated` variant with `surfaceElevated` background and `medium` shadow

### SakinahTextField
- 50pt height, `medium` radius
- `backgroundSecondary` fill, no border by default
- On focus: `primary` 2pt border with `glow` shadow, smooth transition (0.2s)
- Label above field in `captionBold` style, `textSecondary` color
- Error state: `error` border, error message below in `caption` style

## Onboarding Flow — Build Every Screen

### Screen 1: WelcomeScreen
**Layout:**
- Full-screen `background` color
- Top 40% of screen: subtle animated geometric Islamic pattern (use a few `Path` shapes with slow rotation/pulse animation — nothing heavy, just 3-4 interlocking geometric shapes in `primaryLight` with 0.3 opacity, slowly rotating at different speeds)
- Center: App icon or wordmark "noor" in `heroTitle`, lowercase, with `accent` color dot on the arabic-inspired letter styling
- Below: tagline "grow together, guided by what matters" in `body` style, `textSecondary` color, centered
- Bottom safe area: `NoorButton(.primary)` "Get Started", full width with horizontal `base` padding
- Below button: "Already have an account? Sign In" as `ghost` button

**Animations:**
- Geometric pattern fades in over 1.5s on appear
- Wordmark slides up from 20pt below with `noorGentle` spring, 0.3s delay
- Tagline fades in, 0.5s delay
- Button slides up from bottom, 0.7s delay
- All elements use `.transition(.move(edge: .bottom).combined(with: .opacity))`

### Screen 2: SignInScreen
- Sign in with Apple button (use `SignInWithAppleButton` native SwiftUI component)
- Style: `.whiteOutline` in light mode, `.white` in dark mode
- 50pt height, full width, `small` radius
- Above the button: brief copy "Your data stays private. Always." in `caption`, `textTertiary`
- Handle full `ASAuthorization` flow, store user credential in Keychain via `AuthService`

### Screen 3: InvitePartnerScreen
Two paths:
**Path A — "I'm starting us":**
- Generate a 6-character alphanumeric invite code (uppercase, no ambiguous chars like O/0/I/1)
- Display code in a large, styled container: `title1` weight, `primary` color, letter-spaced, each character in its own rounded rect
- "Share with your partner" `NoorButton(.primary)` → opens native share sheet with pre-written message: "Join me on Noor 🌙 Use code: [CODE] — [App Store Link]"
- "Copy Code" as `secondary` button below
- Small animated illustration: two circles gently orbiting each other (representing two people becoming one unit)

**Path B — "I have a code":**
- 6-character code input field (individual character boxes, auto-advance, like a verification code)
- Each box: 48x56pt, `medium` radius, `backgroundSecondary` fill
- On complete: validate against CloudKit, show success checkmark animation or error shake
- On success: haptic `success`, transition to CoupleSetupScreen

### Screen 4: WaitingForPartnerScreen
- Shown when partner hasn't joined yet
- Pulsing animation of two overlapping circles (one for each partner) — one filled, one outlined with gentle pulse
- "Waiting for [partner name or 'your partner']..." in `body` style
- "Resend Invite" `ghost` button
- "Skip for now" text button at bottom — allows solo exploration (du'a of the day, lesson preview)
- CloudKit subscription listens for partner join event → auto-transition on detection

### Screen 5: CoupleSetupScreen
- "Tell us about you two" in `title1`
- Fields:
  - **Your name** — `NoorTextField`, pre-filled from Apple ID if available
  - **Partner's name** — `NoorTextField`
  - **Relationship stage** — segmented picker with 3 options: "Engaged 💍", "Married 🤍", "Long Distance 🌍" — use native `Picker` with `.segmented` style, but custom styled
  - **Anniversary / Special Date** — date picker, compact style. Toggle between Gregorian and Hijri calendar
  - **Du'a language preference** — "Arabic + English", "Arabic + Transliteration", "All three" — horizontal scroll of `NoorCard` selection chips
- "Continue" `NoorButton(.primary)` at bottom
- Save to SwiftData `Couple` model and sync to CloudKit

### Screen 6: FirstPromptScreen
- Transition: gentle zoom + fade from CoupleSetupScreen
- Top: "Your first moment together ✨" in `title2`, `accent` color
- Card: `NoorCard(.elevated)` containing:
  - Prompt category tag: `NoorBadge` with "Gratitude" label
  - Prompt text in `title3`: e.g., "What's one thing about [partner name] that made you smile this week?"
  - Multi-line text input area, 120pt min height, `backgroundSecondary`, `medium` radius
  - "Share" `NoorButton(.primary)`
- After answering: beautiful transition to MainTabView (Today tab) with confetti-like particle burst of small gold dots using Canvas

## Data Models (SwiftData)

```swift
@Model class User {
    @Attribute(.unique) var id: String // Apple ID credential
    var name: String
    var partnerID: String?
    var coupleID: String?
    var duaLanguagePreference: DuaLanguage // enum: arabicEnglish, arabicTransliteration, all
    var notificationTime: Date // default 9:00 AM
    var createdAt: Date
    var subscriptionTier: SubscriptionTier // enum: free, premium
}

@Model class Couple {
    @Attribute(.unique) var id: String
    var user1ID: String
    var user2ID: String
    var user1Name: String
    var user2Name: String
    var inviteCode: String
    var relationshipStage: RelationshipStage // enum: engaged, married, longDistance
    var anniversaryDate: Date?
    var useHijriCalendar: Bool
    var createdAt: Date
    var gardenState: GardenState? // wellness garden data
}

@Model class DailyPrompt {
    @Attribute(.unique) var id: String
    var text: String
    var category: PromptCategory // enum: gratitude, dreams, memories, faith, intimacy, fun
    var scheduledDate: Date
    var isActive: Bool
}

@Model class PromptResponse {
    @Attribute(.unique) var id: String
    var promptID: String
    var coupleID: String
    var userID: String
    var responseText: String
    var createdAt: Date
    var isRevealed: Bool
}

@Model class CheckIn {
    @Attribute(.unique) var id: String
    var coupleID: String
    var userID: String
    var mood: Mood // enum with 5 levels
    var note: String?
    var date: Date
}
```

## Services to Implement

### AuthService
- `signInWithApple()` → returns `User`
- `signOut()`
- `deleteAccount()`
- Persists credential identifier in Keychain using `Security` framework
- Publishes `@Published var currentUser: User?`

### PairingService
- `generateInviteCode()` → 6-char String (exclude O, 0, I, 1, L)
- `validateInviteCode(_ code: String)` → `Couple?`
- `linkPartner(code: String, user: User)` → `Couple`
- `unlinkPartner()` — with confirmation, clears couple data
- Stores invite codes in CloudKit public database for discovery, couple data in private

### CloudKitService
- `save<T: CKRecordConvertible>(_ object: T)`
- `fetch<T: CKRecordConvertible>(predicate: NSPredicate)` → `[T]`
- `subscribe(to recordType: String, predicate: NSPredicate)` — CKSubscription for real-time partner updates
- Handle conflict resolution with last-write-wins for non-critical data
- Offline queue with retry logic

### HapticEngine
```swift
enum HapticType {
    case tap, select, success, celebration, error
}
@MainActor
final class HapticEngine {
    static let shared = HapticEngine()
    func fire(_ type: HapticType) { ... }
}
```

## What to Deliver in This Prompt
1. Complete Xcode project structure with all files created
2. Full design system (Theme, Colors, Typography, Spacing, Components, Modifiers) — fully implemented and functional
3. All data models defined with SwiftData
4. Service protocols and implementations for Auth, Pairing, CloudKit, Haptics
5. Complete onboarding flow (all 6 screens) — fully designed, animated, and functional
6. `ContentView` that routes between onboarding and main app based on auth/pairing state
7. `MainTabView` with 4 tabs (Today, Us, Learn, Ours) — tab bar styled with custom icons and `primary`/`textTertiary` selected/unselected colors. Tab content can be placeholder views for now.

Build this like your portfolio piece. Every pixel matters. Every animation should feel intentional. Every transition should be buttery smooth.
