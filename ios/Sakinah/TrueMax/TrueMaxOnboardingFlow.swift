import Foundation
import SwiftUI

#if canImport(DeclaredAgeRange)
import DeclaredAgeRange
#endif

struct TrueMaxOnboardingFlow: View {
    private enum Step: Int, CaseIterable {
        case welcome
        case ageGate
        case privacy
        case scanTrial
        case paywall
    }

    private enum AgeChoice {
        case adult
        case underage
    }

    private enum SystemAgeStatus {
        case notStarted
        case checking
        case unavailable
        case confirmedAdult
        case blocked
    }

    @Environment(TrueMaxAppState.self) private var appState
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step: Step = .welcome
    @State private var ageChoice: AgeChoice?
    @State private var showsUnderageSupport = false
    @State private var systemAgeStatus: SystemAgeStatus = .notStarted

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            if showsUnderageSupport {
                underageSupport
                    .transition(.opacity)
            } else {
                switch step {
                case .welcome:
                    welcome
                case .ageGate:
                    ageGate
                case .privacy:
                    privacy
                case .scanTrial:
                    NavigationStack {
                        TrueMaxScanRootView(
                            isOnboardingTrial: true,
                            onTrialExit: { move(to: .privacy) },
                            onTrialCompleted: {
                                if subscriptionService.isPremium {
                                    appState.completeOnboarding()
                                } else {
                                    appState.consumeReverseTrial()
                                    move(to: .paywall)
                                }
                            }
                        )
                    }
                case .paywall:
                    TrueMaxPaywallView(
                        showsCloseButton: true,
                        onUnlocked: {
                            appState.dismissPaywall()
                            appState.completeOnboarding()
                        },
                        onClose: {
                            appState.dismissPaywall()
                            move(to: .privacy)
                        }
                    )
                }
            }
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.28),
            value: step
        )
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.28),
            value: showsUnderageSupport
        )
    }

    private var welcome: some View {
        OnboardingScaffold(
            progress: progress(for: .welcome),
            actionTitle: "Check my baseline",
            action: { move(to: .ageGate) }
        ) {
            VStack(spacing: 24) {
                Spacer(minLength: 18)

                TrueMaxBrandLockup()

                FaceMeshIllustration()
                    .frame(height: 250)
                    .padding(.horizontal, 20)
                    .accessibilityLabel("Geometric facial measurement illustration")

                VStack(spacing: 10) {
                    Text("Know what works for you.")
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(TrueMaxPalette.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Complete one private scan, see your measurement ranges and practical next steps, then decide whether to continue.")
                        .font(.body)
                        .foregroundStyle(TrueMaxPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("Designed for adults 18+")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(TrueMaxPalette.textTertiary)

                Spacer(minLength: 8)
            }
        }
    }

    private var ageGate: some View {
        OnboardingScaffold(
            progress: progress(for: .ageGate),
            back: { move(to: .welcome) },
            actionTitle: "Continue",
            actionEnabled: ageChoice != nil,
            action: {
                if ageChoice == .adult, systemAgeStatus != .blocked {
                    move(to: .privacy)
                } else {
                    showsUnderageSupport = true
                }
            }
        ) {
            VStack(spacing: 24) {
                Spacer(minLength: 30)

                TrueMaxIconCircle(
                    symbol: "18.circle",
                    color: TrueMaxPalette.accentLight,
                    size: 72
                )

                VStack(spacing: 10) {
                    Text("TrueMax is for adults")
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(TrueMaxPalette.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Appearance analysis can be sensitive. Please confirm your age before continuing.")
                        .font(.body)
                        .foregroundStyle(TrueMaxPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    AgeChoiceButton(
                        title: "I am 18 or older",
                        detail: "Continue to facial analysis",
                        isSelected: ageChoice == .adult
                    ) {
                        ageChoice = .adult
                        TrueMaxAnalytics.shared.capture(
                            "onboarding age choice made",
                            properties: ["method": "self_attestation"]
                        )
                    }
                    .disabled(
                        systemAgeStatus == .checking
                            || systemAgeStatus == .blocked
                    )

                    AgeChoiceButton(
                        title: "I am under 18",
                        detail: "View age-appropriate support",
                        isSelected: ageChoice == .underage
                    ) {
                        ageChoice = .underage
                        TrueMaxAnalytics.shared.capture(
                            "onboarding age choice made",
                            properties: ["method": "self_attestation"]
                        )
                    }
                    .disabled(systemAgeStatus == .checking)
                }

                ageSignalStatus

#if canImport(DeclaredAgeRange)
                if #available(iOS 26.0, *) {
                    TrueMaxSystemAgeRangeCheck { outcome in
                        handleSystemAgeOutcome(outcome)
                    }
                    .frame(width: 1, height: 1)
                    .accessibilityHidden(true)
                }
#endif

                Spacer(minLength: 16)
            }
        }
    }

    private var privacy: some View {
        OnboardingScaffold(
            progress: progress(for: .privacy),
            back: { move(to: .ageGate) },
            actionTitle: "Start your first scan",
            action: {
                TrueMaxAnalytics.shared.capture("onboarding scan CTA tapped", properties: [
                    "reverse_trial_consumed": appState.reverseTrialConsumed,
                    "is_premium": subscriptionService.isPremium
                ])
                if !subscriptionService.isPremium && appState.reverseTrialConsumed {
                    appState.presentPaywall()
                    move(to: .paywall)
                } else {
                    move(to: .scanTrial)
                }
            }
        ) {
            VStack(spacing: 24) {
                Spacer(minLength: 24)

                TrueMaxIconCircle(
                    symbol: "checkmark",
                    color: TrueMaxPalette.accentLight,
                    size: 72
                )

                VStack(spacing: 10) {
                    Text("Your first baseline is private.")
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(TrueMaxPalette.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Follow the capture guide, then review your real measurement ranges and action plan before choosing a plan.")
                        .font(.body)
                        .foregroundStyle(TrueMaxPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 0) {
                    onboardingPromise(
                        "No account required",
                        icon: "person.crop.circle.badge.checkmark"
                    )
                    Divider().overlay(TrueMaxPalette.border)
                    onboardingPromise(
                        "Face processing stays on this iPhone",
                        icon: "iphone.gen3"
                    )
                    Divider().overlay(TrueMaxPalette.border)
                    onboardingPromise(
                        "Your full baseline appears before plans",
                        icon: "checkmark.seal.fill"
                    )
                }
                .trueMaxCard()

                Text("For the clearest result, use even front lighting, remove glasses, and hold a neutral expression.")
                    .font(.footnote)
                    .foregroundStyle(TrueMaxPalette.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 10)
            }
        }
    }

    private func onboardingPromise(_ title: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(TrueMaxPalette.accentLight)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TrueMaxPalette.textPrimary)
            Spacer(minLength: 4)
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(TrueMaxPalette.positive)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
    }

    private var underageSupport: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Button {
                        showsUnderageSupport = false
                        ageChoice = nil
                        if systemAgeStatus == .blocked {
                            move(to: .welcome)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline.weight(.bold))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Back")
                    Spacer()
                }

                Spacer(minLength: 30)

                TrueMaxIconCircle(
                    symbol: "heart.fill",
                    color: TrueMaxPalette.positive,
                    size: 72
                )

                Text("You deserve support, not a score.")
                        .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                    .multilineTextAlignment(.center)

                Text("TrueMax’s face-analysis tools are designed only for adults, so scanning is not available right now.")
                    .font(.body)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 16) {
                    Label("How you look does not determine your worth.", systemImage: "checkmark.circle.fill")
                    Label("Photos, lighting, and social media can distort how anyone sees themselves.", systemImage: "checkmark.circle.fill")
                    Label("If appearance worries are weighing on you, talk with a trusted adult.", systemImage: "checkmark.circle.fill")
                }
                .font(.body.weight(.medium))
                .foregroundStyle(TrueMaxPalette.textPrimary)
                .symbolRenderingMode(.palette)
                .foregroundStyle(TrueMaxPalette.positive, TrueMaxPalette.textPrimary)
                .trueMaxCard()

                Text("A parent, guardian, school counselor, coach, or healthcare professional can help you find the right support.")
                    .font(.subheadline)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                    .multilineTextAlignment(.center)

                Spacer(minLength: 40)
            }
            .padding(20)
            .trueMaxContentWidth()
        }
    }

    private func progress(for step: Step) -> Double {
        switch step {
        case .welcome:
            return 1.0 / 3.0
        case .ageGate:
            return 2.0 / 3.0
        case .privacy, .scanTrial, .paywall:
            return 1.0
        }
    }

    private func move(to nextStep: Step) {
        TrueMaxAnalytics.shared.capture("onboarding step completed", properties: [
            "to_step": nextStep.rawValue,
            "step_name": String(describing: nextStep)
        ])
        step = nextStep
        TrueMaxAnalytics.shared.screen("onboarding", properties: [
            "step": nextStep.rawValue,
            "step_name": String(describing: nextStep)
        ])
    }

    @ViewBuilder
    private var ageSignalStatus: some View {
        switch systemAgeStatus {
        case .checking:
            HStack(spacing: 9) {
                ProgressView()
                    .tint(TrueMaxPalette.accentLight)
                Text("Checking Apple’s private age-range signal…")
            }
            .font(.footnote)
            .foregroundStyle(TrueMaxPalette.textSecondary)
        case .confirmedAdult:
            Label(
                "Apple’s age-range signal confirms adult access.",
                systemImage: "checkmark.shield.fill"
            )
            .font(.footnote)
            .foregroundStyle(TrueMaxPalette.positive)
            .multilineTextAlignment(.center)
        case .blocked:
            Label(
                "Adult access was not confirmed.",
                systemImage: "lock.shield"
            )
            .font(.footnote)
            .foregroundStyle(TrueMaxPalette.neutral)
        case .notStarted, .unavailable:
            Text("TrueMax uses Apple’s age-range signal when available. Your name, exact birth date, email, and identity are never collected.")
                .font(.footnote)
                .foregroundStyle(TrueMaxPalette.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    private func handleSystemAgeOutcome(_ outcome: TrueMaxSystemAgeOutcome) {
        switch outcome {
        case .checking:
            systemAgeStatus = .checking
        case .adult:
            systemAgeStatus = .confirmedAdult
            ageChoice = .adult
        case .underage:
            systemAgeStatus = .blocked
            ageChoice = .underage
            showsUnderageSupport = true
        case .declined, .unavailable:
            systemAgeStatus = .unavailable
            ageChoice = nil
        }
    }
}

private enum TrueMaxSystemAgeOutcome {
    case checking
    case adult
    case underage
    case declined
    case unavailable
}

#if canImport(DeclaredAgeRange)
@available(iOS 26.0, *)
private struct TrueMaxSystemAgeRangeCheck: View {
    @Environment(\.requestAgeRange) private var requestAgeRange

    let onResult: (TrueMaxSystemAgeOutcome) -> Void

    @State private var hasRequested = false

    var body: some View {
        Color.clear
            .task {
                guard !hasRequested else { return }
                hasRequested = true
                onResult(.checking)

                do {
                    let response = try await requestAgeRange(ageGates: 18)

                    switch response {
                    case .sharing(let ageRange):
                        if let lowerBound = ageRange.lowerBound,
                           lowerBound >= 18 {
                            onResult(.adult)
                        } else if let upperBound = ageRange.upperBound,
                                  upperBound < 18 {
                            onResult(.underage)
                        } else {
                            onResult(.unavailable)
                        }
                    case .declinedSharing:
                        onResult(.declined)
                    @unknown default:
                        onResult(.unavailable)
                    }
                } catch {
                    onResult(.unavailable)
                }
            }
    }
}
#endif

private struct OnboardingScaffold<Content: View>: View {
    let progress: Double
    var back: (() -> Void)?
    let actionTitle: String
    var actionEnabled = true
    let action: () -> Void
    let content: Content

    init(
        progress: Double,
        back: (() -> Void)? = nil,
        actionTitle: String,
        actionEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.progress = progress
        self.back = back
        self.actionTitle = actionTitle
        self.actionEnabled = actionEnabled
        self.action = action
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                if let back {
                    Button(action: back) {
                        Image(systemName: "chevron.left")
                            .font(.headline.weight(.bold))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Back")
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }

                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == activeDot ? TrueMaxPalette.accentLight : TrueMaxPalette.textTertiary.opacity(0.45))
                            .frame(width: index == activeDot ? 8 : 6, height: index == activeDot ? 8 : 6)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Onboarding progress")
                .accessibilityValue(activeDot == 2 ? "Ready for first scan" : "Setup in progress")

                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)

            ScrollView {
                content
                    .padding(.horizontal, 20)
                    .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)

            Button(actionTitle, action: action)
                .buttonStyle(TrueMaxPrimaryButtonStyle())
                .disabled(!actionEnabled)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(.ultraThinMaterial)
        }
    }

    private var activeDot: Int {
        max(0, min(2, Int(ceil(progress * 3)) - 1))
    }
}

private struct AgeChoiceButton: View {
    let title: String
    let detail: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(
                        isSelected ? TrueMaxPalette.accentLight : TrueMaxPalette.textTertiary
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(TrueMaxPalette.textPrimary)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(TrueMaxPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(18)
            .background(
                isSelected
                    ? TrueMaxPalette.accent.opacity(0.11)
                    : TrueMaxPalette.card,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? TrueMaxPalette.accentLight : TrueMaxPalette.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
