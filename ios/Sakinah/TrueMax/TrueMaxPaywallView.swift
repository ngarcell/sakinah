import SwiftUI
import RevenueCat

private enum TrueMaxPaywallCopy {
    static let freeTrialDays = 3
    static var annualTrialCTA: String { "Start \(freeTrialDays)-Day Free Trial" }
    static var annualTrialDisclosure: String { "\(freeTrialDays) days free" }
}

struct TrueMaxPaywallView: View {
    private enum TrialEligibilityPresentation: Equatable {
        case checking
        case eligible
        case ineligible
        case unavailable
    }

    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let showsCloseButton: Bool
    let onUnlocked: () -> Void
    var onClose: (() -> Void)?

    @State private var selectedPlan: SubscriptionService.Plan = .annual
    @State private var trialEligibility: TrialEligibilityPresentation = .checking

    init(
        showsCloseButton: Bool = true,
        onUnlocked: @escaping () -> Void,
        onClose: (() -> Void)? = nil
    ) {
        self.showsCloseButton = showsCloseButton
        self.onUnlocked = onUnlocked
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(spacing: 22) {
                    topBar

                    TrueMaxBrandLockup(compact: true)

                    VStack(spacing: 8) {
                        Text("Know what works for you.")
                            .font(.title2.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(TrueMaxPalette.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Unlimited private analysis. Cancel anytime.")
                            .font(.body)
                            .foregroundStyle(TrueMaxPalette.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    FaceMeshIllustration()
                        .frame(height: 170)
                        .padding(.horizontal, 34)
                        .accessibilityHidden(true)

                    featureList

                    VStack(alignment: .leading, spacing: 12) {
                        Group {
                            if dynamicTypeSize.isAccessibilitySize {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Choose your plan")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(TrueMaxPalette.textPrimary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                HStack {
                                    Text("Choose your plan")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(TrueMaxPalette.textPrimary)
                                }
                            }
                        }

                        Group {
                            if dynamicTypeSize.isAccessibilitySize {
                                VStack(spacing: 12) {
                                    monthlyPlanCard
                                    annualPlanCard
                                }
                            } else {
                                HStack(alignment: .top, spacing: 12) {
                                    monthlyPlanCard
                                    annualPlanCard
                                }
                            }
                        }
                    }

                    purchaseSection

                    Text("An internet connection is needed to complete or restore a purchase. Facial analysis and saved results work locally after that.")
                        .font(.footnote)
                        .foregroundStyle(TrueMaxPalette.textTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 18) {
                        Button("Terms") {
                            openURL(TrueMaxBrand.termsURL)
                        }
                        Button("Privacy") {
                            openURL(TrueMaxBrand.privacyURL)
                        }
                        Button("Support") {
                            openURL(TrueMaxBrand.supportURL)
                        }
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                    .padding(.bottom, 18)
                }
                .padding(.horizontal, 20)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
        .task {
            _ = await subscriptionService.preparePaywall(forceRefresh: false)
            await refreshTrialEligibility()
        }
        .onChange(of: selectedPlan) { _, _ in
            subscriptionService.clearError()
            trialEligibility = .checking
            Task {
                await refreshTrialEligibility()
            }
        }
        .onChange(of: subscriptionService.isPremium) { _, isPremium in
            if isPremium {
                onUnlocked()
            }
        }
    }

    private var topBar: some View {
        HStack {
            if showsCloseButton {
                TrueMaxCloseButton {
                    onClose?()
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer()

            Button("Restore") {
                Task {
                    await subscriptionService.restorePurchases()
                    if subscriptionService.isPremium {
                        onUnlocked()
                    }
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(TrueMaxPalette.textSecondary)
            .disabled(subscriptionService.isLoading)
        }
        .padding(.top, 4)
    }

    private var featureList: some View {
        VStack(spacing: 0) {
            PaywallFeatureRow(
                symbol: "viewfinder",
                title: "Unlimited private scans",
                detail: "No scan packs or pay-per-result charges"
            )
            Divider().overlay(TrueMaxPalette.border)
            PaywallFeatureRow(
                symbol: "ruler",
                title: "Facial measurements",
                detail: "Transparent ranges and methodology"
            )
            Divider().overlay(TrueMaxPalette.border)
            PaywallFeatureRow(
                symbol: "list.bullet.clipboard",
                title: "Personal action plan",
                detail: "Practical grooming and presentation guidance"
            )
            Divider().overlay(TrueMaxPalette.border)
            PaywallFeatureRow(
                symbol: "sparkles",
                title: "Hair and color tools",
                detail: "Style previews saved only on your device"
            )
            Divider().overlay(TrueMaxPalette.border)
            PaywallFeatureRow(
                symbol: "chart.xyaxis.line",
                title: "Progress comparisons",
                detail: "Private history with no social ranking"
            )
        }
        .trueMaxCard()
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    if trialEligibility == .unavailable {
                        trialEligibility = .checking
                        await refreshTrialEligibility()
                        return
                    }

                    let purchased = await subscriptionService.purchase(plan: selectedPlan)
                    if purchased {
                        onUnlocked()
                    }
                }
            } label: {
                HStack(spacing: 9) {
                    if subscriptionService.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(primaryCTATitle)
                }
            }
            .buttonStyle(TrueMaxPrimaryButtonStyle())
            .disabled(
                subscriptionService.isPurchasing
                    || !subscriptionService.planDetails(for: selectedPlan).isAvailable
                    || trialEligibility == .checking
            )

            Text(billingDisclosure)
                .font(.caption)
                .foregroundStyle(TrueMaxPalette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let error = subscriptionService.purchaseError {
                Text(error)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(TrueMaxPalette.caution)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Purchase message: \(error)")
            }
        }
    }

    private var monthlyPlanCard: some View {
        PlanChoiceCard(
            details: subscriptionService.planDetails(for: .monthly),
            isSelected: selectedPlan == .monthly
        ) {
            selectedPlan = .monthly
        }
    }

    private var annualPlanCard: some View {
        PlanChoiceCard(
            details: subscriptionService.planDetails(for: .annual),
            isSelected: selectedPlan == .annual
        ) {
            selectedPlan = .annual
        }
    }

    private var primaryCTATitle: String {
        if subscriptionService.isPurchasing {
            return "Confirming…"
        }

        if trialEligibility == .checking {
            return "Checking Eligibility…"
        }

        if trialEligibility == .unavailable {
            return "Retry Plan Check"
        }

        if selectedPlan == .annual {
            return TrueMaxPaywallCopy.annualTrialCTA
        }

        return "Continue Pro — Monthly"
    }

    private var billingDisclosure: String {
        let details = subscriptionService.planDetails(for: selectedPlan)
        let price = details.localizedPrice ?? "the displayed App Store price"

        if trialEligibility == .unavailable {
            return "Free-trial eligibility could not be verified. Reconnect and retry so TrueMax can show the correct billing terms before purchase."
        }

        if selectedPlan == .annual {
            return "\(TrueMaxPaywallCopy.annualTrialDisclosure), then \(price) per \(details.cadence). Subscription renews automatically unless cancelled at least 24 hours before the current period ends."
        }

        return "\(price) per \(details.cadence). Subscription renews automatically unless cancelled at least 24 hours before the current period ends."
    }

    private func refreshTrialEligibility() async {
        let plan = selectedPlan
        let status = await subscriptionService.trialEligibility(for: plan)
        guard selectedPlan == plan else { return }

        switch status {
        case .eligible:
            trialEligibility = .eligible
        case .ineligible, .noIntroOfferExists:
            trialEligibility = .ineligible
        case .unknown:
            trialEligibility = .unavailable
        @unknown default:
            trialEligibility = .unavailable
        }
    }
}

private struct PlanChoiceCard: View {
    let details: SubscriptionService.PlanDetails
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(details.displayName.uppercased())
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(
                            isSelected
                                ? TrueMaxPalette.accentLight
                                : TrueMaxPalette.textSecondary
                        )
                    Spacer(minLength: 4)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(
                            isSelected
                                ? TrueMaxPalette.accentLight
                                : TrueMaxPalette.textTertiary
                        )
                }

                if details.plan == .annual {
                    Text(savingsText)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(TrueMaxPalette.positive)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(TrueMaxPalette.positive.opacity(0.12), in: Capsule())
                } else {
                    Text("FLEXIBLE")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(TrueMaxPalette.textTertiary)
                        .padding(.vertical, 4)
                }

                Spacer(minLength: 5)

                Text(details.localizedPrice ?? "Loading…")
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let equivalent = details.monthlyEquivalentPrice {
                    Text("\(equivalent) per month")
                        .font(.caption)
                        .foregroundStyle(TrueMaxPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("per \(details.cadence)")
                        .font(.caption)
                        .foregroundStyle(TrueMaxPalette.textSecondary)
                }

                Text(details.plan == .annual
                    ? "3 days free, then billed once per year"
                    : "Flexible monthly access")
                    .font(.caption)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(15)
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .leading)
            .background(
                isSelected
                    ? TrueMaxPalette.accent.opacity(0.11)
                    : TrueMaxPalette.card,
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        isSelected ? TrueMaxPalette.accentLight : TrueMaxPalette.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(details.displayName), \(details.localizedPrice ?? "price loading")"
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var savingsText: String {
        if let percent = details.annualSavingsPercent {
            return "BEST VALUE · SAVE \(percent)%"
        }
        return "BEST VALUE"
    }
}

private struct PaywallFeatureRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(TrueMaxPalette.accentLight)
                .frame(width: 36, height: 36)
                .background(TrueMaxPalette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(TrueMaxPalette.positive)
        }
        .padding(.vertical, 10)
    }
}
