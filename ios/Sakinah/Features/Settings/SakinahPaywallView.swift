import RevenueCat
import RevenueCatUI
import SwiftUI
import SwiftData

enum SakinahPaywallEntryPoint: Hashable, Sendable, Identifiable {
    case starterPlan
    case generic
    case dailyHabit
    case guidedLesson
    case conversationPacks
    case sharedSpace
    case weeklyReflection
    case settings

    var id: String { identifier }

    var identifier: String {
        switch self {
        case .starterPlan:
            return "starter_plan"
        case .generic:
            return "generic"
        case .dailyHabit:
            return "daily_habit"
        case .guidedLesson:
            return "guided_lesson"
        case .conversationPacks:
            return "conversation_packs"
        case .sharedSpace:
            return "shared_space"
        case .weeklyReflection:
            return "weekly_reflection"
        case .settings:
            return "settings"
        }
    }

    var contextMessage: String? {
        switch self {
        case .starterPlan:
            return "Continue the first week you already started and keep your saved answer, daily prompts, and shared space open."
        case .generic:
            return "Keep your private ritual, guided reflection, and shared space available in one place."
        case .dailyHabit:
            return "Keep the daily rhythm going with tomorrow’s prompt and the space you are building together."
        case .guidedLesson:
            return "Unlock the lesson that matches what you want more care and clarity around right now."
        case .conversationPacks:
            return "Unlock the deeper conversation packs so you can keep the right question close."
        case .sharedSpace:
            return "Unlock the shared journal, letters, goals, wishes, and memories you keep together."
        case .weeklyReflection:
            return "Unlock the weekly reflection so your shared rhythm keeps turning into real progress."
        case .settings:
            return "Choose the plan that keeps your private space, daily prompts, and guided lessons available."
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

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
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
            if selectedOffering == nil && (subscriptionService.isLoadingProducts || isPreparingPaywall) {
                loadingState
                    .background(paywallBackground.ignoresSafeArea())
            } else if let offering = selectedOffering {
                hostedPaywall(offering: offering)
            } else {
                unavailableState
                    .background(paywallBackground.ignoresSafeArea())
            }
        }
        .task {
            isPreparingPaywall = true
            _ = await subscriptionService.preparePaywall(forceRefresh: false)
            isPreparingPaywall = false

            if subscriptionService.isPremium {
                finalizeUnlockAndDismiss()
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
                finalizeUnlockAndDismiss()
            }
        }
    }

    private var selectedOffering: Offering? {
        if entryPoint == .settings {
            subscriptionService.manageOffering
        } else {
            subscriptionService.currentOffering
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

            Text("Loading current access and available plans.")
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

            Text("Premium access")
                .font(SakinahFont.title2)
                .foregroundStyle(SakinahColor.textPrimary)

            Text(unavailableMessage)
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
                    markStarterPaywallSeenIfNeeded()
                    appState.dismissPresentedPaywall()
                    dismiss()
                }
                .font(SakinahFont.captionBold)
                .foregroundStyle(SakinahColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, SakinahSpacing.base)
    }

    private var unavailableMessage: String {
        if let purchaseError = subscriptionService.purchaseError {
            return purchaseError
        }

        return "Plans are unavailable right now. Please try again soon."
    }

    private func hostedPaywall(offering: Offering) -> some View {
        RevenueCatUI.PaywallView(
            offering: offering,
            displayCloseButton: !isMandatory
        )
        .tint(SakinahColor.primary)
        .customPaywallVariables(paywallVariables)
        .onPurchaseStarted { _ in
            purchaseNotice = nil
            subscriptionService.clearError()
        }
        .onPurchaseCompleted { customerInfo in
            subscriptionService.syncCustomerInfo(customerInfo)
            HapticEngine.shared.fire(.celebration)
            finalizeUnlockAndDismiss()
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
                finalizeUnlockAndDismiss()
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
                markStarterPaywallSeenIfNeeded()
                appState.dismissPresentedPaywall()
                dismiss()
            }
        }
    }

    private var paywallVariables: [String: CustomVariableValue] {
        var variables = entryPoint.revenueCatVariables
        variables["recommended_plan"] = .string("annual")
        variables["saved_answer_present"] = .bool(appState.currentStarterPlan != nil)

        if let relationshipStage = appState.currentCouple?.relationshipStage.rawValue {
            variables["relationship_stage"] = .string(relationshipStage)
        }
        if let focus = appState.currentUser?.relationshipFocus?.rawValue {
            variables["focus"] = .string(focus)
        }
        if let urgency = appState.currentUser?.relationshipUrgency?.rawValue {
            variables["urgency"] = .string(urgency)
        }
        if let friction = appState.currentUser?.relationshipFriction?.rawValue {
            variables["friction"] = .string(friction)
        }

        return variables
    }

    private func finalizeUnlockAndDismiss() {
        guard !hasHandledUnlock else { return }
        hasHandledUnlock = true

        appState.currentUser?.requiresInitialSubscriptionUnlock = false
        appState.currentUser?.hasSeenInitialSubscriptionPaywall = true
        appState.currentUser?.touch()
        try? modelContext.save()
        appState.handleSubscriptionState(isPremium: true)
        appState.preparePostPurchaseExperience()
        appState.dismissPresentedPaywall()
        dismiss()
    }

    private func markStarterPaywallSeenIfNeeded() {
        guard entryPoint == .starterPlan,
              appState.currentUser?.requiresInitialSubscriptionUnlock == true,
              !subscriptionService.isPremium else { return }

        appState.markInitialStarterPaywallSeen()
        try? modelContext.save()
    }
}
