import SwiftUI
import AuthenticationServices

struct SignInScreen: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: SakinahSpacing.xl) {
            HStack {
                Button {
                    HapticEngine.shared.fire(.tap)
                    vm.advance(to: .welcome)
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

            VStack(spacing: SakinahSpacing.base) {
                ZStack {
                    Circle().fill(SakinahColor.primaryLight).frame(width: 96, height: 96)
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 38, weight: .regular))
                        .foregroundStyle(SakinahColor.primary)
                }
                .glow(color: SakinahColor.primary, radius: 30, opacity: 0.2)

                Text("Welcome back")
                    .font(SakinahFont.title1)
                    .foregroundStyle(SakinahColor.textPrimary)

                Text("Sign in securely with Apple.\nYour data stays private. Always.")
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: SakinahSpacing.sm) {
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    vm.handleSignIn(result: result)
                }
                .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
                .frame(height: Theme.buttonHeight)
                .clipShape(.rect(cornerRadius: SakinahRadius.small))
                .sakinahShadow(.medium)

                Text("Your data stays private. Always.")
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.textTertiary)
            }
            .padding(.horizontal, SakinahSpacing.base)
            .padding(.bottom, SakinahSpacing.base)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
