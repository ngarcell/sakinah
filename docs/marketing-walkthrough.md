# TrueMax simulator marketing walkthrough

## What the recording shows

The recording-only **Play 55-second walkthrough** runs one continuous,
hands-free product story:

1. The Home baseline and weekly focus scroll into view.
2. The scan checklist opens.
3. A bundled fictional adult capture is analyzed with the real on-device `TrueMaxAnalysisEngine` (Apple Vision), saved through protected `TrueMaxStorage`, and inserted into SwiftData.
4. The resulting face guide, measurement ranges, and personalized action plan appear.
5. The plan switches from **This week** to **All**.
6. The style library changes category, opens a live guide overlay on the saved capture, and saves the style to favorites.
7. History enters selection mode, selects the new and four-week-old records, opens comparison, and scrolls through the changed ranges.

The older record is deterministic seeded data. The current record is created during playback. Their fixed demo IDs let replay replace only demo records; ordinary user scans are never deleted or modified.

## Launch from Xcode

The launcher is intentionally unavailable from the shipping onboarding and
purchase flows. Exposing it there would bypass the adult/privacy gates and
replace the promised real baseline with seeded demo data.

For a recording-only launch:

1. Open `ios/Sakinah.xcodeproj` in Xcode.
2. Select an iPhone simulator and the Sakinah scheme.
3. In **Product → Scheme → Edit Scheme → Run → Arguments**, add `-TrueMaxMarketingDemo`.
4. Run the app and tap **Play 55-second walkthrough**.
5. Use the pause or replay controls in the bottom playback card if needed.

## Record a clean vertical video

Use an iPhone 15 Pro, iPhone 16 Pro, or equivalent portrait simulator at 100% scale. Start recording before tapping Play:

```bash
xcrun simctl io booted recordVideo --codec=h264 ~/Desktop/truemax-walkthrough.mp4
```

Press `Control-C` after the final TrueMax title card. The resulting portrait H.264 file is suitable for a 9:16 TikTok/Reels edit; trim the launcher tap and final hold as desired.

Keep **Slow Animations** disabled in the simulator. Close other GPU-heavy apps if capture is not smooth. The walkthrough intentionally uses native SwiftUI transitions and one local Vision request, with no network calls during playback.

## Demo image provenance

The two bundled images are fictional adult model assets generated for this simulator demonstration after reviewing the supplied product-design references in `docs/`. They are clean captures, not screenshots or UI placeholders:

- `Assets.xcassets/TrueMaxDemoCurrent.imageset`
- `Assets.xcassets/TrueMaxDemoEarlier.imageset`

Both records remain local to the app container and can be removed with the normal TrueMax data controls.
