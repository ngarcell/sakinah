import SwiftUI
import SwiftData
import RevenueCatUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var subscriptionService = SubscriptionService.shared
    @State private var showPaywall = false
    @State private var showCustomerCenter = false
    @State private var showDeleteConfirm = false
    @State private var deleteText = ""
    @State private var showFinalDelete = false
    @State private var showUnlinkConfirm = false
    @State private var showShareSheet = false

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
            .sheet(isPresented: $showPaywall) {
                SakinahPaywallView(entryPoint: .settings)
            }
            .sheet(isPresented: $showCustomerCenter) {
                CustomerCenterView()
                    .onCustomerCenterRestoreCompleted { customerInfo in
                        subscriptionService.syncCustomerInfo(customerInfo)
                    }
                    .onCustomerCenterRestoreFailed { error in
                        subscriptionService.setError(from: error)
                    }
            }
            .alert("Unlink Partner", isPresented: $showUnlinkConfirm) {
                Button("Unlink", role: .destructive) {
                    appState.currentCouple?.user2ID = ""
                    appState.currentCouple?.user2Name = "Partner"
                    try? modelContext.save()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the partner link. Your data stays safe.")
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

            if appState.daysTogether > 0 {
                HStack {
                    Text("Days together")
                        .font(SakinahFont.body)
                    Spacer()
                    Text("\(appState.daysTogether)")
                        .font(SakinahFont.headline)
                        .foregroundStyle(SakinahColor.accent)
                }
            }

            Button(role: .destructive) {
                showUnlinkConfirm = true
            } label: {
                Text("Unlink Partner")
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
        Section("Premium") {
            HStack {
                Text("Plan")
                    .font(SakinahFont.body)
                Spacer()
                Text(subscriptionService.currentPlanName)
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(subscriptionService.isPremium ? SakinahColor.accent : SakinahColor.textSecondary)
            }

            if !subscriptionService.isPremium {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Open the full version")
                                .font(SakinahFont.headline)
                                .foregroundStyle(.white)
                            Text("Every pack, your shared journal, letters, goals, and wishlists.")
                                .font(SakinahFont.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.white)
                    }
                    .padding(SakinahSpacing.md)
                    .background(
                        LinearGradient(
                            colors: [SakinahColor.accent, SakinahColor.accentWarm],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(.rect(cornerRadius: SakinahRadius.small))
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                Text(subscriptionUpgradeMessage)
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.textSecondary)
            }

            if subscriptionService.canOpenCustomerCenter {
                Button("Subscription Help") {
                    showCustomerCenter = true
                }
            }

            if subscriptionService.isPremium || subscriptionService.managementURL != nil {
                Button("Manage Subscription") {
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

    private var subscriptionUpgradeMessage: String {
        if subscriptionService.annualDisplayPrice != "Price unavailable" {
            return "Best value • \(subscriptionService.annualDisplayPrice) for couples building a real rhythm together."
        }

        if let featuredUpgradePrice = subscriptionService.featuredUpgradePrice {
            return "\(featuredUpgradePrice) • every pack plus your full shared space"
        }

        return "Every pack plus your full shared space."
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section("Preferences") {
            Picker("Du'a language", selection: Binding(
                get: { appState.currentUser?.duaLanguagePreference ?? .all },
                set: { newVal in appState.currentUser?.duaLanguagePreference = newVal; try? modelContext.save() }
            )) {
                ForEach(DuaLanguage.allCases, id: \.self) { lang in
                    Text(lang.label).tag(lang)
                }
            }

            Toggle("Hijri calendar", isOn: Binding(
                get: { appState.currentCouple?.useHijriCalendar ?? false },
                set: { newVal in appState.currentCouple?.useHijriCalendar = newVal; try? modelContext.save() }
            ))
            .tint(SakinahColor.primary)

            Picker("Appearance", selection: $selectedAppearance) {
                Text("System").tag(0)
                Text("Light").tag(1)
                Text("Dark").tag(2)
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
                Text("You control what stays private and what gets shared with your partner.")
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
            }

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
            }

            Link("Privacy Policy", destination: URL(string: "https://socialreporthq.com/sakinah/privacy")!)
            Link("Terms of Service", destination: URL(string: "https://socialreporthq.com/sakinah/terms")!)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(SakinahColor.textTertiary)
            }

            Button("Rate Sakinah") {
                if let url = URL(string: "https://apps.apple.com/app/id6762535411?action=write-review") {
                    UIApplication.shared.open(url)
                }
            }

            Button {
                let url = URL(string: "https://apps.apple.com/app/id6762535411")!
                let av = UIActivityViewController(activityItems: [
                    "We've been using Sakinah for our daily check-ins. Thought you'd like it too.",
                    url
                ], applicationActivities: nil)
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let root = scene.windows.first?.rootViewController {
                    root.present(av, animated: true)
                }
            } label: {
                Label("Share Sakinah", systemImage: "square.and.arrow.up")
            }

            Link("Contact Support", destination: URL(string: "https://socialreporthq.com/sakinah/support")!)
        }
    }

    private func deleteAllData() {
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
            try modelContext.save()
        } catch {}

        appState.currentUser = nil
        appState.currentCouple = nil
        appState.route = .onboarding
    }
}
