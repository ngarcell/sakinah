# Prompt 2 of 3 — Core Experience: Today Tab & Us Tab

You are continuing to build "Sakinah," a premium couples wellness iOS app for Muslim couples. Prompt 1 established the project structure, design system, data models, services, and onboarding. All design tokens (SakinahColor, SakinahFont, SakinahSpacing, etc.), components (SakinahButton, SakinahCard, SakinahTextField), modifiers (PressModifier, ShimmerModifier, GlowModifier), and models are already implemented. Reference them throughout.

Now build the two most important tabs — the screens users will interact with every single day. These must be flawless.

**Tech constraints reminder:** iOS 17+, Swift 6, SwiftUI only, SwiftData, CloudKit, zero third-party dependencies. All design tokens from Prompt 1 are available.

---

## TODAY TAB — "Today"

The Today tab is the home screen. It's what users see when they open the app. It must feel warm, alive, and immediately inviting — like opening a letter from someone who cares about you.

### TodayView Layout (Scrollable)

**Structure:** `ScrollView` with `.scrollIndicators(.hidden)`, content arranged vertically:

1. **Header** (sticky, not in scroll)
   - Left: "Salaam, [user first name] 🌙" in `title2` style
   - Right: partner's avatar circle (32pt, initials if no photo) with green online dot if partner checked in today
   - Below: "[Day of week], [Date]" in `caption`, `textSecondary`. Show Hijri date alongside if enabled.
   - Background: `background` color, no border, subtle bottom fade into scroll content

2. **Daily Prompt Card** — the hero element, takes up ~40% of viewport
3. **Daily Du'a Card** — below prompt
4. **Quick Check-In Card** — below du'a
5. **Bottom breathing room** — 100pt spacer for comfortable thumb reach

---

### Daily Prompt Card — Detailed Spec

This is the most important UI element in the entire app. It must feel special every time.

**Card Container:**
- `SakinahCard(.elevated)` with extra vertical padding (24pt top, 20pt bottom)
- Subtle gradient overlay at top edge: `accent` at 5% opacity → transparent, 40pt tall. This gives it a warm "glow" feeling.
- Full width with `base` (16pt) horizontal margin

**State Machine — 4 States:**

**State 1: UNANSWERED (neither partner has answered)**
- Top-left: `SakinahBadge` with prompt category (e.g., "Gratitude ✨", "Faith 🤲", "Dreams 💭")
- Center: prompt text in `title3` style, `textPrimary`, centered, max 3 lines
- Below: multi-line `TextEditor` with placeholder "Share your thoughts...", `backgroundSecondary` fill, `medium` radius, 100pt min height. Character count "0/500" in `caption` at bottom-right of field.
- Bottom: "Share with [partner name]" `SakinahButton(.primary)`, full width
- Micro-animation: prompt text has a very subtle typewriter-style reveal on first appearance (each word fades in sequentially over 1.5s total, using `animation(.easeIn.delay(wordIndex * 0.08))`)

**State 2: WAITING (user answered, partner hasn't)**
- Show user's response in a speech bubble (right-aligned, `primaryLight` background, `medium` radius, tail pointing right)
- Center: pulsing "waiting for [partner name]..." with ellipsis animation (3 dots cycling opacity)
- Two overlapping circles animation (like in onboarding) — one filled (you), one pulsing outline (partner)
- "Nudge [partner name] 💌" `SakinahButton(.secondary)` — sends a push notification to partner

**State 3: PARTNER_ANSWERED (partner answered, user hasn't — or both answered, not yet revealed)**
- When BOTH have answered: show "You're both ready! ✨" with a shimmering `accent` glow around the card border
- "Reveal Together" `SakinahButton(.primary)` with `GlowModifier` pulsing in `accent` color
- This button triggers the reveal animation

**State 4: REVEALED**
- Split view: user's response on right (speech bubble, `primaryLight`), partner's response on left (speech bubble, `accentLight`)
- Names above each bubble in `captionBold`
- Below: reaction bar — row of 5 emoji (❤️ 😂 🥺 🤲 ✨) as tappable circles, 40pt each. Selected emoji scales up with `sakinahBounce` spring and gets a subtle `glow` shadow.
- Optional: "Reply" text button opens a reply sheet

**Reveal Animation (the crown jewel):**
When user taps "Reveal Together":
1. Card background briefly flashes to `accent` at 10% opacity (0.15s)
2. Haptic: `celebration` pattern fires
3. Both bubbles scale from 0 → 1 with `sakinahBounce` spring, staggered by 0.15s (user's first, partner's second)
4. Small particle burst: 12-15 tiny circles in `accent` color scatter outward from center of card using `Canvas` + `TimelineView`, fade out over 1.2s
5. Category badge transitions color to `accent`
6. Total animation duration: ~1.5s

---

### Daily Du'a Card

**Card Container:** `SakinahCard` (standard, not elevated), full width

**Layout:**
- Top-left: "Du'a of the Day" in `captionBold`, `textSecondary`
- Top-right: small speaker icon (SF Symbol `speaker.wave.2.fill`) in `primary` color, tappable → plays audio
- Center section (vertical stack, centered):
  - Arabic text in `arabic` font style (24pt), right-to-left, `textPrimary`, centered
  - 8pt spacer
  - Transliteration in `bodySmall`, italic, `textSecondary`, centered
  - 12pt spacer
  - Divider line: 40pt wide, 1pt, `divider` color, centered
  - 8pt spacer
  - English translation in `body`, `textPrimary`, centered
- Bottom: source attribution "— [Hadith source]" in `caption`, `textTertiary`, right-aligned

**Audio Playback:**
- Use `AVAudioPlayer` with bundled MP3 files (one per du'a)
- On tap: icon animates to `speaker.wave.3.fill` with a subtle pulse while playing
- Audio session category: `.playback` with `.duckOthers` option

**Visual Polish:**
- Subtle Islamic geometric border pattern along the top edge of the card — implement as a thin (2pt) repeating geometric `Path` in `primaryLight` color at 30% opacity
- On first appearance, Arabic text fades in from 0 opacity over 0.8s

---

### Quick Check-In Card

**Card Container:** `SakinahCard`, full width

**Layout:**
- "How are you today?" in `headline` style, centered
- Row of 5 mood options, evenly spaced horizontally:
  - Each: emoji (36pt) + label below in `caption`
  - Options: 😊 "Great" | 🙂 "Good" | 😐 "Okay" | 😔 "Low" | 😢 "Tough"
  - Unselected: 60% opacity, no background
  - Selected: full opacity, `primaryLight` circle background (48pt), scale 1.15, `sakinahBounce` spring
  - Haptic `select` on tap
- After selecting: "Anything you'd like to share?" text field slides down with `sakinahGentle` spring (optional, collapsible)
- If partner has checked in today: small banner below → "[Partner name] is feeling [mood emoji] today" in `bodySmall`, `textSecondary`, with the emoji. Tappable to see their note if they wrote one.

**Behavior:**
- Check-in persists to SwiftData `CheckIn` model and syncs via CloudKit
- Only one check-in per day; if already done, show completed state with option to update
- Completed state: selected mood is shown, "Update" ghost button available

---

## US TAB — "Us"

The Us tab is the couple's shared wellness view. It should feel intimate, reflective, and organic — not clinical or dashboard-like.

### UsView Layout (Scrollable)

1. **Header:** "Us" in `title1`, centered. Below: "[X] days growing together" in `bodySmall`, `textSecondary`, with the number in `accent` color and `headline` weight.
2. **Wellness Garden** — the hero visual, ~45% of viewport height
3. **Weekly Reflection Card** — below garden, shown on Fridays or if overdue
4. **Milestones & Memories** — horizontal scroll of milestone/memory cards

---

### Wellness Garden — Detailed Spec

The garden is a visual metaphor for the couple's relationship health. It must feel alive, organic, and emotionally resonant.

**Canvas Implementation:**
- Use SwiftUI `Canvas` with `TimelineView(.animation)` for smooth ambient animations
- Garden scene: soft gradient ground (bottom 25% of canvas — `primaryLight` to `success` at 15% opacity), subtle sky gradient (top — `background` to `primaryLight` at 5%)
- Five plants, evenly spaced along the ground, each representing a dimension:

| Plant | Dimension | Visual Style |
|-------|----------|-------------|
| 🌱 Sprout/Flower | Communication | Slender stem with round petals, `primary` tones |
| 🌿 Leafy Bush | Quality Time | Wide, bushy shape, `success` tones |
| ⭐ Star Flower | Spiritual Connection | Star-shaped bloom, `accent` tones |
| 🌸 Soft Blossom | Emotional Safety | Rounded, soft petals, warm pink tones |
| 🌳 Small Tree | Growth | Tree shape with canopy, `primary`/`success` mixed |

**Growth States (per plant, 5 levels):**
- Level 1 (Neglected): small seed/sprout, muted colors, slight droop animation
- Level 2 (Emerging): small plant, half-height, partial color
- Level 3 (Growing): medium plant, upright, moderate color
- Level 4 (Thriving): full-size, vibrant color, subtle sway animation
- Level 5 (Blooming): full-size with flowers/particles, gentle sparkle, sway animation

**Ambient Animations:**
- All plants have gentle sway: sinusoidal horizontal offset, ±2pt, period 3-5s (different per plant to avoid synchronized movement)
- Level 4-5 plants: occasional sparkle particles (tiny `accent` dots that fade in/out, 1-2 per plant, random timing)
- Subtle "breeze" effect every 15s: all plants sway more for 2s then settle back

**Growth Algorithm:**
Plant level is calculated from:
- Weekly reflection scores for that dimension (0-5 scale, primary input)
- Daily engagement (completed prompts/check-ins contribute small fractional growth to Communication and Emotional Safety)
- Decay: plants lose 0.5 levels per week with zero engagement in that dimension (minimum level 1)
- Store in `GardenState` model on the `Couple` object

**Interactivity:**
- Tap any plant → bottom sheet slides up with:
  - Plant name and dimension label
  - Current level description: "Your communication is thriving 🌸"
  - Mini trend: last 4 weeks as small dots (filled = good, outline = needs attention)
  - If level ≤ 2: gentle suggestion: "Try answering today's prompt together" with a direct link to Today tab

**Below Garden:**
- Small legend row: 5 tiny icons (one per plant type) with dimension names in `caption`, `textTertiary`, horizontal scroll if needed

---

### Weekly Reflection — Detailed Spec

**Visibility:** Shown every Friday (configurable), or if the previous week's reflection is incomplete. Hidden if already completed this week.

**Card Container:** `SakinahCard(.elevated)` with `accent` left border (4pt wide, full height, `large` top-left and bottom-left radius)

**Layout:**
- "Weekly Reflection" in `title3` + "🪞" emoji
- "Take a quiet moment to reflect on your week together." in `bodySmall`, `textSecondary`
- 5 questions, shown one at a time (paged, not all at once):
  - "I felt heard by my partner this week" → Communication
  - "We made quality time for each other" → Quality Time
  - "We connected spiritually this week" → Spiritual Connection
  - "I felt emotionally safe and supported" → Emotional Safety
  - "We grew or learned something together" → Growth
- Each question screen:
  - Question text in `headline`, centered
  - 5-point scale as tappable circles in a row: labeled "Not at all" ... "Absolutely"
  - Selected: filled `primary` circle with white number, scale 1.1
  - Unselected: `backgroundSecondary` circle with `textSecondary` number
  - Progress dots at bottom (5 dots, filled = answered)
  - "Next" `SakinahButton(.primary)` or "Submit" on last question
- On submit: haptic `success`, garden updates with growth animation (plants visibly grow/shrink based on new scores), brief celebration overlay if all scores ≥ 4

**Privacy:**
- Toggle at top of reflection: "Share with [partner name]" — default OFF
- If shared: partner sees aggregate score, not individual question responses
- If both share: compare view unlocked in premium (side-by-side radar chart)

---

### Milestones & Memories

**Horizontal ScrollView** with `.scrollTargetBehavior(.viewAligned)` for snappy paging

**Milestone Cards (auto-generated):**
- Compact `SakinahCard`, 280pt wide × 160pt tall
- Top: milestone icon (🎉, 💯, 🌙, etc.) large, centered
- Center: "100 days together!" in `title3`, centered
- Bottom: date in `caption`, `textTertiary`
- Background: subtle radial gradient from `accentLight` center to `surface` edge
- Auto-detected milestones: 7 days, 30 days, 100 days, 6 months, each anniversary, first Ramadan together, first Eid together

**Memory Cards (user-created):**
- Same dimensions as milestone cards
- Photo thumbnail (if saved) with rounded corners, fills top 60% of card
- Caption below in `bodySmall`, max 2 lines
- Date in `caption`
- "+" card at the end of the scroll: dashed border, `textTertiary` "Add a memory" text + camera icon, taps to open photo picker + caption input sheet

**Add Memory Sheet:**
- `.sheet` presentation with `medium` detent
- Photo picker (`.photosPicker` modifier) at top
- Caption `SakinahTextField` below
- Date picker (defaults to today)
- "Save Memory" `SakinahButton(.primary)`
- Save to SwiftData, sync to CloudKit (photo stored as CKAsset)

---

## Content Data Structures

### Prompts JSON Schema (Prompts.json, bundle 30+ for testing)
```json
[
  {
    "id": "prompt_001",
    "text": "What's one small thing {partnerName} did this week that made your day better?",
    "category": "gratitude",
    "tags": ["beginner", "light"],
    "minRelationshipDays": 0
  },
  {
    "id": "prompt_002",
    "text": "If you could relive one moment from your relationship, which would it be and why?",
    "category": "memories",
    "tags": ["deep", "reflective"],
    "minRelationshipDays": 30
  }
]
```
- `{partnerName}` is a template variable replaced at runtime
- `minRelationshipDays`: prompts unlock progressively (prevents deep intimacy questions on day 1)
- `ContentService` loads from bundle, selects one per day based on: date hash + couple ID (deterministic so both partners see the same prompt), category rotation, and relationship maturity

### Du'as JSON Schema (Duas.json, bundle 20+ for testing)
```json
[
  {
    "id": "dua_001",
    "arabic": "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ",
    "transliteration": "Rabbana hab lana min azwajina wa dhurriyyatina qurrata a'yun",
    "translation": "Our Lord, grant us from among our spouses and offspring comfort to our eyes",
    "source": "Quran 25:74",
    "audioFile": "dua_001.mp3",
    "category": "family"
  }
]
```

---

## What to Deliver in This Prompt
1. Complete `TodayView` with all 3 cards (prompt, du'a, check-in), fully animated and functional
2. Complete prompt state machine (4 states) with all transitions and the reveal animation
3. Du'a card with Arabic rendering, transliteration, translation, and audio playback
4. Check-in card with mood selection, partner visibility, and persistence
5. Complete `UsView` with wellness garden (Canvas-rendered, 5 plants, ambient animation), weekly reflection (paged flow), and milestones/memories horizontal scroll
6. `ContentService` implementation: loads prompts/du'as from bundle JSON, selects daily content deterministically
7. All CloudKit sync for prompt responses, check-ins, reflections, and memories
8. All animations, haptics, and transitions as specified

Every interaction must feel intentional. The reveal animation must give users goosebumps. The garden must feel alive. The check-in must feel like someone genuinely caring, not a survey.
