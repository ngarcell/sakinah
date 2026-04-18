import SwiftUI

struct WaitingForPartnerScreen: View {
    @Bindable var vm: OnboardingViewModel
    @State private var pulse: CGFloat = 1
    @State private var rotate: Double = 0

    var body: some View {
        VStack(spacing: SakinahSpacing.xl) {
            HStack {
                Button {
                    HapticEngine.shared.fire(.tap)
                    vm.advance(to: .invitePartner)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(SakinahColor.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(SakinahColor.surface)
                        .clipShape(Circle())
                        .sakinahShadow(.subtle)
                }
                .pressScale()
                Spacer()
            }
            .padding(.horizontal, SakinahSpacing.base)
            .padding(.top, SakinahSpacing.sm)

            Spacer()

            ZStack {
                Circle()
                    .fill(SakinahColor.primary.opacity(0.06))
                    .frame(width: 220, height: 220)
                    .scaleEffect(pulse)
                Circle()
                    .fill(SakinahColor.primary.opacity(0.10))
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulse * 1.05)

                HStack(spacing: -20) {
                    Circle()
                        .fill(SakinahColor.primary)
                        .frame(width: 72, height: 72)
                        .overlay(Text(vm.yourName.prefix(1).uppercased())
                            .font(SakinahFont.title2).foregroundStyle(.white))
                        .glow(color: SakinahColor.primary, radius: 24, opacity: 0.35)
                    Circle()
                        .stroke(SakinahColor.accent, lineWidth: 2.5)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "questionmark")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(SakinahColor.accent)
                        )
                }
                .rotationEffect(.degrees(rotate))
            }

            VStack(spacing: SakinahSpacing.sm) {
                Text("Waiting for your partner…")
                    .font(SakinahFont.title2)
                    .foregroundStyle(SakinahColor.textPrimary)
                Text("They'll enter the code you shared and you'll pair up automatically.")
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SakinahSpacing.xl)
            }

            Spacer()

            VStack(spacing: SakinahSpacing.sm) {
                SakinahButton(title: "Resend Invite", icon: "paperplane", variant: .secondary) {
                    HapticEngine.shared.fire(.select)
                }
                Button {
                    HapticEngine.shared.fire(.tap)
                    vm.advance(to: .coupleSetup)
                } label: {
                    Text("Skip for now — explore solo")
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)
                        .underline()
                }
                .pressScale()
            }
            .padding(.horizontal, SakinahSpacing.base)
            .padding(.bottom, SakinahSpacing.base)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { pulse = 1.15 }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { rotate = 8 }
        }
    }
}
