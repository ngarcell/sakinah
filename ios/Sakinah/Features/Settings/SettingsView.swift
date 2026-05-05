import SwiftUI
import SwiftData
import RevenueCatUI
import UIKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var subscriptionService = SubscriptionService.shared
    @State private var showCustomerCenter = false
    @State private var showDeleteConfirm = false
    @State private var deleteText = ""
    @State private var paywallEntryPoint: SakinahPaywallEntryPoint?

    // Notification preferences
    @AppStorage("dailyPromptNotif") private var dailyPromptNotif = true
    @AppStorage("partnerActivityNotif") private var partnerActivityNotif = true
    @AppStorage("weeklyReflectionNotif") private var weeklyReflectionNotif = true
    @AppStorage("milestoneNotif") private var milestoneNotif = true
    @AppStorage("reflectionDay") private var reflectionDay = 6
    @AppStorage("selectedAppearance") private var selectedAppearance = 0
    @AppStorage("hapticEnabled") private var hapticEnabled = true

    @State private var promptTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0))!

    var body: some View {
        NavigationStack {
            List {
                profileSection
                notificationsSection
                subscriptionSection
                preferencesSection
                privacySection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCustomerCenter) {
                CustomerCenterView()
                    .onCustomerCenterRestoreCompleted { customerInfo in
                        subscriptionService.syncCustomerInfo(customerInfo)
                    }
                    .onCustomerCenterRestoreFailed { error in
                        subscriptionService.setError(from: error)
                    }
            }
            .alert("Delete All Data", isPresented: $showDeleteConfirm) {
                TextField("Type DELETE to confirm", text: $deleteText)
                Button("Delete Everything", role: .destructive) {
                    if deleteText.uppercased() == "DELETE" {
                        deleteAllData()
                    }
                }
                Button("Cancel", role: .cancel) { deleteText = "" }
            } message: {
                Text("This will permanently erase all your data. This cannot be undone.")
            }
            .sheet(isPresented: invitePromptBinding) {
                PartnerInvitePromptView()
            }
            .sheet(item: $paywallEntryPoint) { entryPoint in
                SakinahPaywallView(entryPoint: entryPoint, isMandatory: false)
            }
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section {
            HStack(spacing: SakinahSpacing.md) {
                ZStack {
                    Circle()
                        .fill(SakinahColor.primaryLight)
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(SakinahColor.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.userName)
                        .font(SakinahFont.headline)
                        .foregroundStyle(SakinahColor.textPrimary)
                    Text("with \(appState.partnerName)")
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)
                }
            }

            HStack {
                Text("Shared space")
                    .font(SakinahFont.body)
                Spacer()
                Text(sharedSpaceStatusText)
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(sharedSpaceStatusColor)
            }

            if let relationshipDurationDays = appState.relationshipDurationDays, relationshipDurationDays > 0 {
                HStack {
                    Text("Days together")
                        .font(SakinahFont.body)
                    Spacer()
                    Text("\(relationshipDurationDays)")
                        .font(SakinahFont.headline)
                        .foregroundStyle(SakinahColor.accent)
                }
            }

            if appState.pairingStatus != .paired {
                Button("Invite spouse") {
                    appState.showPartnerInvitePrompt = true
                }
            } else if let syncStatusText {
                Text(syncStatusText)
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.textTertiary)
            }
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Daily prompt", isOn: $dailyPromptNotif)
                .tint(SakinahColor.primary)

            if dailyPromptNotif {
                DatePicker("Prompt time", selection: $promptTime, displayedComponents: .hourAndMinute)
                    .onChange(of: promptTime) { _, time in
                        Task { await NotificationService.shared.scheduleDailyPrompt(at: time) }
                    }
            }

            Toggle("Partner activity", isOn: $partnerActivityNotif)
                .tint(SakinahColor.primary)
            Toggle("Weekly reflection", isOn: $weeklyReflectionNotif)
                .tint(SakinahColor.primary)

            if weeklyReflectionNotif {
                Picker("Reflection day", selection: $reflectionDay) {
                    Text("Friday").tag(6)
                    Text("Saturday").tag(7)
                    Text("Sunday").tag(1)
                }
            }

            Toggle("Milestones", isOn: $milestoneNotif)
                .tint(SakinahColor.primary)
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        Section("Plan") {
            HStack {
                Text("Access")
                    .font(SakinahFont.body)
                Spacer()
                Text(subscriptionService.currentPlanName)
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(subscriptionService.isPremium ? SakinahColor.accent : SakinahColor.textSecondary)
            }

            if !subscriptionService.isPremium {
                Text(subscriptionService.featuredPlanSummary)
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)

                Button("See Plans") {
                    paywallEntryPoint = .settings
                }
                .foregroundStyle(SakinahColor.primary)
            }

            if subscriptionService.canOpenCustomerCenter {
                Button("Manage Plan") {
                    showCustomerCenter = true
                }
            }

            if subscriptionService.isPremium || subscriptionService.managementURL != nil {
                Button("Billing & Renewal") {
                    openURL(subscriptionService.managementURL ?? Constants.manageSubscriptionsURL)
                }
            }

            Button("Restore Access") {
                Task { await subscriptionService.restorePurchases() }
            }
            .foregroundStyle(SakinahColor.primary)

            if subscriptionService.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }

            if let purchaseError = subscriptionService.purchaseError {
                Text(purchaseError)
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.error)
            }
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section("Preferences") {
            Picker("Du'a language", selection: Binding(
                get: { appState.currentUser?.duaLanguagePreference ?? .all },
                set: { newVal in
                    appState.currentUser?.duaLanguagePreference = newVal
                    appState.currentUser?.touch()
                    try? modelContext.save()
                    Task { await CloudKitService.shared.syncIfPossible(appState: appState, context: modelContext) }
                }
            )) {
                ForEach(DuaLanguage.allCases, id: \.self) { lang in
                    Text(lang.label).tag(lang)
                }
            }

            Toggle("Hijri calendar", isOn: Binding(
                get: { appState.currentCouple?.useHijriCalendar ?? false },
                set: { newVal in
                    appState.currentCouple?.useHijriCalendar = newVal
                    appState.currentCouple?.touch()
                    try? modelContext.save()
                    Task { await CloudKitService.shared.syncIfPossible(appState: appState, context: modelContext) }
                }
            ))
            .tint(SakinahColor.primary)

            Picker("Appearance", selection: $selectedAppearance) {
                ForEach(AppAppearanceMode.allCases) { appearance in
                    Text(appearance.title).tag(appearance.rawValue)
                }
            }

            Toggle("Haptic feedback", isOn: $hapticEnabled)
                .tint(SakinahColor.primary)
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        Section("Privacy & Data") {
            HStack(spacing: SakinahSpacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(SakinahColor.success)
                Text("Your entries stay on your device and in the iCloud-shared space you create with your spouse. Only the spouse you invite can access shared items.")
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
            }

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
            }

            Link("Privacy", destination: URL(string: "https://socialreporthq.com/sakinah/privacy")!)
            Link("Terms", destination: URL(string: "https://socialreporthq.com/sakinah/terms")!)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("More") {
            Button("Rate the App") {
                if let url = URL(string: "https://apps.apple.com/app/id6762535411?action=write-review") {
                    UIApplication.shared.open(url)
                }
            }

            Button {
                let url = URL(string: "https://apps.apple.com/app/id6762535411")!
                let av = UIActivityViewController(activityItems: [
                    "We’ve been using Sakinah for a calmer daily marriage ritual. Thought you might like it too.",
                    url
                ], applicationActivities: nil)
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let root = scene.windows.first?.rootViewController {
                    root.present(av, animated: true)
                }
            } label: {
                Label("Share Sakinah", systemImage: "square.and.arrow.up")
            }

            Link("Help", destination: URL(string: "https://socialreporthq.com/sakinah/support")!)
        }
    }

    private var invitePromptBinding: Binding<Bool> {
        Binding(
            get: { appState.showPartnerInvitePrompt },
            set: { appState.showPartnerInvitePrompt = $0 }
        )
    }

    private var sharedSpaceStatusText: String {
        switch appState.pairingStatus {
        case .solo:
            return "Not set up"
        case .readyToInvite:
            return "Ready to invite"
        case .invitationSent:
            return "Invite sent"
        case .invitationWaiting:
            return "Waiting to connect"
        case .paired:
            return "Connected"
        }
    }

    private var sharedSpaceStatusColor: Color {
        switch appState.pairingStatus {
        case .paired:
            return SakinahColor.success
        case .invitationSent, .invitationWaiting:
            return SakinahColor.accent
        default:
            return SakinahColor.textSecondary
        }
    }

    private var syncStatusText: String? {
        switch appState.syncStatus {
        case .upToDate(let date):
            return "Last synced \(DateFormatting.timeAgo(date))"
        case .syncing:
            return "Syncing shared space"
        case .failed(let message):
            return message
        case .idle:
            return nil
        }
    }

    private func deleteAllData() {
        if let couple = appState.currentCouple {
            Task {
                await CloudKitService.shared.deleteRemoteDataIfOwned(couple: couple)
            }
        }

        do {
            try modelContext.delete(model: User.self)
            try modelContext.delete(model: Couple.self)
            try modelContext.delete(model: CheckIn.self)
            try modelContext.delete(model: PromptResponse.self)
            try modelContext.delete(model: DailyPrompt.self)
            try modelContext.delete(model: WeeklyReflection.self)
            try modelContext.delete(model: Memory.self)
            try modelContext.delete(model: JournalEntry.self)
            try modelContext.delete(model: LoveLetter.self)
            try modelContext.delete(model: SharedGoal.self)
            try modelContext.delete(model: WishItem.self)
            try modelContext.delete(model: Lesson.self)
            try modelContext.delete(model: OnboardingDraft.self)
            try modelContext.save()
        } catch {}

        appState.currentUser = nil
        appState.currentCouple = nil
        appState.pendingShareDetected = false
        appState.showPartnerInvitePrompt = false
        appState.handleSubscriptionState(isPremium: false)
        appState.route = .onboarding
    }
}
