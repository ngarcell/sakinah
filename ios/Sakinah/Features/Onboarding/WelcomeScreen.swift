import SwiftUI

struct WelcomeScreen: View {
    @Bindable var vm: OnboardingViewModel
    @State private var appeared = false
    @State private var taglineVisible = false
    @State private var ctaVisible = false

    var body: some View {
        ZStack {
            // Layered background
            SakinahColor.background.ignoresSafeArea()
            
            // Subtle radial warmth
            RadialGradient(
                colors: [SakinahColor.accent.opacity(0.08), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                GeometricPattern()
                    .frame(height: 280)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.9)
                    .animation(.easeOut(duration: 1.8), value: appeared)

                Spacer(minLength: SakinahSpacing.lg)

                // Brand mark
                VStack(spacing: SakinahSpacing.lg) {
                    HStack(spacing: 2) {
                        Text("sakinah")
                            .font(.system(size: 44, weight: .bold, design: .serif))
                            .foregroundStyle(SakinahColor.textPrimary)
                            .tracking(-0.5)
                        Circle()
                            .fill(SakinahColor.accent)
                            .frame(width: 8, height: 8)
                            .offset(y: 12)
                            .glow(color: SakinahColor.accent, radius: 12, opacity: 0.6)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    // Identity-first tagline
                    VStack(spacing: SakinahSpacing.xs) {
                        Text("Your marriage, growing daily")
                            .font(SakinahFont.body)
                            .foregroundStyle(SakinahColor.textSecondary)

                        Text("Built for Muslim couples who want more\nthan just getting by.")
                            .font(SakinahFont.caption)
                            .foregroundStyle(SakinahColor.textTertiary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    .opacity(taglineVisible ? 1 : 0)
                    .offset(y: taglineVisible ? 0 : 10)
                }

                Spacer()

                // CTA
                VStack(spacing: SakinahSpacing.md) {
                    SakinahButton(title: "Start Growing Together") {
                        HapticEngine.shared.fire(.tap)
                        vm.advance(to: .invitePartner)
                    }

                    Text("No account needed \u{00B7} Everything stays on your device")
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textTertiary)
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.bottom, SakinahSpacing.xl)
                .opacity(ctaVisible ? 1 : 0)
                .offset(y: ctaVisible ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.2)) {
                appeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.6)) {
                taglineVisible = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(1.0)) {
                ctaVisible = true
            }
        }
    }
}
