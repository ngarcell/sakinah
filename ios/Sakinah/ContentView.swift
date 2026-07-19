import SwiftUI

struct ContentView: View {
    @Environment(TrueMaxAppState.self) private var appState
    @Environment(SubscriptionService.self) private var subscriptionService

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            if appState.isBootstrapping {
                TrueMaxLoadingView(
                    title: "Preparing TrueMax",
                    detail: "Checking your access and setting up private on-device analysis."
                )
            } else if !appState.hasCompletedOnboarding {
                TrueMaxOnboardingFlow()
                    .id(appState.onboardingRestartID)
            } else if !subscriptionService.isPremium {
                TrueMaxPaywallView(
                    showsCloseButton: false,
                    onUnlocked: {
                        appState.selectedTab = .home
                    }
                )
            } else {
                TrueMaxMainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.24), value: appState.isBootstrapping)
        .animation(.easeInOut(duration: 0.24), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.24), value: subscriptionService.isPremium)
        .sheet(isPresented: medicalDisclaimerBinding) {
            MedicalDisclaimerView {
                appState.acknowledgeDisclaimer()
            }
            .interactiveDismissDisabled()
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
    }

    private var medicalDisclaimerBinding: Binding<Bool> {
        Binding(
            get: {
                appState.requiresMedicalDisclaimer
                    && subscriptionService.isPremium
            },
            set: { _ in }
        )
    }
}

private struct MedicalDisclaimerView: View {
    let acknowledge: () -> Void

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            VStack(spacing: 20) {
                TrueMaxIconCircle(
                    symbol: "heart.text.square",
                    color: TrueMaxPalette.accentLight,
                    size: 58
                )

                Text("A note before your first scan")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                    .multilineTextAlignment(.center)

                Text(
                    "TrueMax provides cosmetic measurements and general grooming or style guidance. It does not provide medical, dermatological, or psychological advice, and its estimates are not a diagnosis."
                )
                .font(.body)
                .foregroundStyle(TrueMaxPalette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

                Button("I understand", action: acknowledge)
                    .buttonStyle(TrueMaxPrimaryButtonStyle())
            }
            .padding(24)
            .trueMaxContentWidth()
        }
    }
}
