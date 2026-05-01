import RevenueCat
import RevenueCatUI
import SwiftUI

enum SakinahPaywallEntryPoint: Hashable, Sendable {
    case generic
    case dailyHabit
    case conversationPacks
    case sharedSpace
    case settings

    var identifier: String {
        switch self {
        case .generic:
            return "generic"
        case .dailyHabit:
            return "daily_habit"
        case .conversationPacks:
            return "conversation_packs"
        case .sharedSpace:
            return "shared_space"
        case .settings:
            return "settings"
        }
    }

    var contextMessage: String? {
        switch self {
        case .generic:
            return "Open every conversation pack plus your private shared space in one place."
        case .dailyHabit:
            return "You’ve already built a rhythm together. Premium opens every pack and your private space."
        case .conversationPacks:
            return "Premium opens the full prompt library so the next conversation is always within reach."
        case .sharedSpace:
            return "Premium opens your shared journal, letters, goals, and wishlists in one private space."
        case .settings:
            return "See every plan in one place and unlock the parts of this space you’ll come back to most."
        }
    }

    var revenueCatVariables: [String: CustomVariableValue] {
        var variables: [String: CustomVariableValue] = [
            "entry_point": .string(identifier),
            "has_context_message": .bool(contextMessage != nil),
        ]

        if let contextMessage {
            variables["context_message"] = .string(contextMessage)
        }

        return variables
    }
}

struct SakinahPaywallView: View {
    let entryPoint: SakinahPaywallEntryPoint
    let isMandatory: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionService = SubscriptionService.shared
    @State private var purchaseNotice: String?
    @State private var isPreparingPaywall = true
    @State private var hasHandledUnlock = false

    init(entryPoint: SakinahPaywallEntryPoint = .generic, isMandatory: Bool = false) {
        self.entryPoint = entryPoint
        self.isMandatory = isMandatory
    }

    var body: some View {
        Group {
            if subscriptionService.currentOffering == nil && (subscriptionService.isLoadingProducts || isPreparingPaywall) {
                loadingState
            } else if let offering = subscriptionService.currentOffering {
                hostedPaywall(offering: offering)
            } else {
                unavailableState
            }
        }
        .background(paywallBackground.ignoresSafeArea())
        .task {
            isPreparingPaywall = true
            _ = await subscriptionService.preparePaywall(forceRefresh: false)
            isPreparingPaywall = false

            if subscriptionService.isPremium {
                dismissPaywall()
            }
        }
        .alert("Unable to Update Access", isPresented: purchaseNoticeBinding) {
            Button("OK") {
                purchaseNotice = nil
                subscriptionService.clearError()
            }
        } message: {
            Text(purchaseNotice ?? "")
        }
        .onChange(of: subscriptionService.currentTier) { _, tier in
            if tier == .premium {
                dismissPaywall()
            }
        }
    }

    private var purchaseNoticeBinding: Binding<Bool> {
        Binding(
            get: { purchaseNotice != nil },
            set: { isPresented in
                if !isPresented {
                    purchaseNotice = nil
                    subscriptionService.clearError()
                }
            }
        )
    }

    private var paywallBackground: some View {
        ZStack {
            SakinahColor.background

            LinearGradient(
                colors: [
                    SakinahColor.primary.opacity(0.14),
                    SakinahColor.background.opacity(0.94),
                    SakinahColor.surface.opacity(0.98),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var loadingState: some View {
        VStack(spacing: SakinahSpacing.lg) {
            ProgressView()
                .tint(SakinahColor.primary)

            Text("Checking plans")
                .font(SakinahFont.title2)
                .foregroundStyle(SakinahColor.textPrimary)

            Text("Loading current options and checking your access.")
                .font(SakinahFont.bodySmall)
                .foregroundStyle(SakinahColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SakinahSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(SakinahSpacing.base)
    }

    private var unavailableState: some View {
        VStack(spacing: SakinahSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(SakinahColor.accent)

            Text("Premium Access")
                .font(SakinahFont.title2)
                .foregroundStyle(SakinahColor.textPrimary)

            Text(subscriptionService.purchaseError ?? "Plans are unavailable right now. Please try again.")
                .font(SakinahFont.bodySmall)
                .foregroundStyle(SakinahColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SakinahSpacing.xl)

            Button {
                Task { _ = await subscriptionService.preparePaywall(forceRefresh: true) }
            } label: {
                Text("Try Again")
                    .font(SakinahFont.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [SakinahColor.accent, SakinahColor.accentWarm],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: SakinahRadius.medium)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, SakinahSpacing.xl)

            if !isMandatory {
                Button("Continue for now") {
                    dismiss()
                }
                .font(SakinahFont.captionBold)
                .foregroundStyle(SakinahColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, SakinahSpacing.base)
    }

    private func hostedPaywall(offering: Offering) -> some View {
        RevenueCatUI.PaywallView(
            offering: offering,
            displayCloseButton: !isMandatory
        )
        .tint(SakinahColor.primary)
        .safeAreaInset(edge: .top, spacing: 0) {
            if isMandatory {
                mandatoryBanner
            }
        }
        .customPaywallVariables(entryPoint.revenueCatVariables)
        .onPurchaseStarted { _ in
            purchaseNotice = nil
            subscriptionService.clearError()
        }
        .onPurchaseCompleted { customerInfo in
            subscriptionService.syncCustomerInfo(customerInfo)
            HapticEngine.shared.fire(.celebration)
            dismissPaywall()
        }
        .onPurchaseCancelled {
            purchaseNotice = nil
        }
        .onPurchaseFailure { error in
            subscriptionService.setError(from: error)
            purchaseNotice = subscriptionService.purchaseError
        }
        .onRestoreStarted {
            purchaseNotice = nil
            subscriptionService.clearError()
        }
        .onRestoreCompleted { customerInfo in
            subscriptionService.syncCustomerInfo(customerInfo)

            if subscriptionService.isPremium {
                dismissPaywall()
            } else {
                purchaseNotice = "No previous access was found to restore."
            }
        }
        .onRestoreFailure { error in
            subscriptionService.setError(from: error)
            purchaseNotice = subscriptionService.purchaseError
        }
        .onRequestedDismissal {
            if !isMandatory {
                dismiss()
            }
        }
    }

    private var mandatoryBanner: some View {
        HStack(alignment: .top, spacing: SakinahSpacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your first answer is saved")
                    .font(SakinahFont.headline)
                    .foregroundStyle(SakinahColor.textPrimary)
                Text("Continue with daily prompts, lessons, and your shared space.")
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.textSecondary)
            }

            Spacer()

            Button {
                Task { await subscriptionService.restorePurchases() }
            } label: {
                if subscriptionService.isRestoringPurchases {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Restore")
                        .font(SakinahFont.captionBold)
                        .foregroundStyle(SakinahColor.primary)
                }
            }
            .disabled(subscriptionService.isRestoringPurchases)
        }
        .padding(.horizontal, SakinahSpacing.base)
        .padding(.top, SakinahSpacing.sm)
        .padding(.bottom, SakinahSpacing.md)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func dismissPaywall() {
        guard !hasHandledUnlock else { return }
        hasHandledUnlock = true
        dismiss()
    }
}
