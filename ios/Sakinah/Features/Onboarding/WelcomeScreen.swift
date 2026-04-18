import SwiftUI

struct WelcomeScreen: View {
    @Bindable var vm: OnboardingViewModel
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SakinahColor.background, SakinahColor.backgroundSecondary],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                GeometricPattern()
                    .frame(height: 340)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 1.5), value: appeared)

                Spacer(minLength: SakinahSpacing.xl)

                VStack(spacing: SakinahSpacing.md) {
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

                    Text(Constants.tagline)
                        .font(SakinahFont.body)
                        .foregroundStyle(SakinahColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SakinahSpacing.xl)
                        .opacity(appeared ? 1 : 0)
                }

                Spacer()

                VStack(spacing: SakinahSpacing.sm) {
                    SakinahButton(title: "Get Started") {
                        vm.advance(to: .signIn)
                    }
                    Button {
                        HapticEngine.shared.fire(.tap)
                        vm.advance(to: .signIn)
                    } label: {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundStyle(SakinahColor.textSecondary)
                            Text("Sign In")
                                .foregroundStyle(SakinahColor.primary)
                                .fontWeight(.semibold)
                        }
                        .font(SakinahFont.bodySmall)
                    }
                    .pressScale()
                    .padding(.top, SakinahSpacing.xs)
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.bottom, SakinahSpacing.base)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.3)) {
                appeared = true
            }
        }
    }
}
