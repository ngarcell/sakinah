import SwiftUI

struct WelcomeScreen: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var appeared = false
    @State private var taglineVisible = false
    @State private var ctaVisible = false

    var body: some View {
        ZStack {
            SakinahColor.background.ignoresSafeArea()

            RadialGradient(
                colors: [SakinahColor.accent.opacity(0.1), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 360
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

                    VStack(spacing: SakinahSpacing.xs) {
                        if vm.hasPendingShareInvitation {
                            SakinahBadge(
                                text: "Shared space waiting",
                                color: SakinahColor.accent,
                                tintedBackground: SakinahColor.accentLight
                            )
                        }

                        Text(vm.hasPendingShareInvitation ? "Your spouse already opened the shared space." : "A private ritual for Muslim marriages")
                            .font(SakinahFont.body)
                            .foregroundStyle(SakinahColor.textSecondary)
                            .multilineTextAlignment(.center)

                        Text(vm.hasPendingShareInvitation ? "Finish your side, save one honest answer, and step back into the same space together." : "Begin with one honest answer, shape a calmer first week, and keep the parts of your marriage that matter in one quiet place.")
                            .font(SakinahFont.caption)
                            .foregroundStyle(SakinahColor.textTertiary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    .opacity(taglineVisible ? 1 : 0)
                    .offset(y: taglineVisible ? 0 : 10)
                }

                Spacer()

                VStack(spacing: SakinahSpacing.md) {
                    SakinahButton(title: vm.hasPendingShareInvitation ? "Continue My Setup" : "Begin") {
                        HapticEngine.shared.fire(.tap)
                        vm.advance(to: .context, context: modelContext)
                    }

                    Text("You will save your first answer before choosing a plan.")
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
