import SwiftUI
import AVFoundation

struct DailyDuaCard: View {
    let dua: DuaData
    let duaLanguage: DuaLanguage
    @State private var isPlaying = false
    @State private var arabicAppeared = false
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        SakinahCard {
            VStack(spacing: 0) {
                // Geometric border pattern at top
                geometricBorder
                    .frame(height: 2)
                    .padding(.bottom, SakinahSpacing.md)

                // Header
                HStack {
                    Text("Du'a of the Day")
                        .font(SakinahFont.captionBold)
                        .foregroundStyle(SakinahColor.textSecondary)
                    Spacer()
                    Button {
                        toggleAudio()
                    } label: {
                        Image(systemName: isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(SakinahColor.primary)
                            .symbolEffect(.variableColor, isActive: isPlaying)
                            .frame(width: 36, height: 36)
                            .background(SakinahColor.primaryLight)
                            .clipShape(Circle())
                    }
                    .pressScale()
                }
                .padding(.bottom, SakinahSpacing.lg)

                // Arabic text
                if duaLanguage == .arabicEnglish || duaLanguage == .all || duaLanguage == .arabicTransliteration {
                    Text(dua.arabic)
                        .font(SakinahFont.arabic)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .environment(\.layoutDirection, .rightToLeft)
                        .lineSpacing(8)
                        .opacity(arabicAppeared ? 1 : 0)
                        .padding(.bottom, SakinahSpacing.sm)
                }

                // Transliteration
                if duaLanguage == .arabicTransliteration || duaLanguage == .all {
                    Text(dua.transliteration)
                        .font(SakinahFont.bodySmall)
                        .italic()
                        .foregroundStyle(SakinahColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, SakinahSpacing.md)
                }

                // Divider
                Rectangle()
                    .fill(SakinahColor.divider)
                    .frame(width: 40, height: 1)
                    .padding(.bottom, SakinahSpacing.sm)

                // English translation
                if duaLanguage == .arabicEnglish || duaLanguage == .all {
                    Text(dua.translation)
                        .font(SakinahFont.body)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.bottom, SakinahSpacing.md)
                }

                // Source attribution
                HStack {
                    Spacer()
                    Text("— \(dua.source)")
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textTertiary)
                }
            }
        }
        .padding(.horizontal, SakinahSpacing.base)
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                arabicAppeared = true
            }
        }
        .onDisappear {
            audioPlayer?.stop()
            isPlaying = false
        }
    }

    // MARK: - Geometric Border

    private var geometricBorder: some View {
        Canvas { context, size in
            let patternWidth: CGFloat = 16
            let count = Int(size.width / patternWidth) + 1
            let y = size.height / 2

            for i in 0..<count {
                let x = CGFloat(i) * patternWidth
                var diamond = Path()
                diamond.move(to: CGPoint(x: x, y: 0))
                diamond.addLine(to: CGPoint(x: x + patternWidth / 2, y: y))
                diamond.addLine(to: CGPoint(x: x + patternWidth, y: 0))
                diamond.addLine(to: CGPoint(x: x + patternWidth / 2, y: -y))
                diamond.closeSubpath()

                context.stroke(diamond, with: .color(SakinahColor.primaryLight.opacity(0.3)), lineWidth: 0.5)
            }
        }
    }

    // MARK: - Audio

    private func toggleAudio() {
        HapticEngine.shared.fire(.tap)

        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
            return
        }

        // Try to load audio file from bundle
        let fileName = dua.audioFile.replacingOccurrences(of: ".mp3", with: "")
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            // Graceful fallback: brief haptic feedback instead
            HapticEngine.shared.fire(.select)
            withAnimation {
                isPlaying = true
            }
            // Simulate playback duration
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                withAnimation {
                    isPlaying = false
                }
            }
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlaying = true

            // Monitor completion
            Task { @MainActor in
                while audioPlayer?.isPlaying == true {
                    try? await Task.sleep(for: .milliseconds(500))
                }
                withAnimation {
                    isPlaying = false
                }
            }
        } catch {
            isPlaying = false
        }
    }
}
