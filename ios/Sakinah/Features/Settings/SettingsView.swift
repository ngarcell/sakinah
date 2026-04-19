import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false
    @State private var deleteText = ""
    @State private var showFinalDelete = false
    @State private var showUnlinkConfirm = false

    // Notification preferences
    @State private var dailyPromptNotif = true
    @State private var promptTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var partnerActivityNotif = true
    @State private var weeklyReflectionNotif = true
    @State private var reflectionDay = 6 // Friday
    @State private var milestoneNotif = true

    // Appearance
    @State private var selectedAppearance = 0 // 0=system, 1=light, 2=dark
    @State private var hapticEnabled = true

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
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                SakinahPaywallView()
                    .presentationDetents([.large])
            }
            .alert("Unlink Partner?", isPresented: $showUnlinkConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Unlink", role: .destructive) {
                    // Handle unlink
                }
            } message: {
                Text("This will disconnect your account from \(appState.partnerName). Your data will be preserved.")
            }
            .alert("Delete All Data", isPresented: $showDeleteConfirm) {
                TextField("Type DELETE to confirm", text: $deleteText)
                Button("Cancel", role: .cancel) { deleteText = "" }
                Button("Delete Everything", role: .destructive) {
                    if deleteText == "DELETE" {
                        showFinalDelete = true
                    }
                }
                .disabled(deleteText != "DELETE")
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .alert("Are you absolutely sure?", isPresented: $showFinalDelete) {
                Button("Cancel", role: .cancel) {}
                Button("Yes, delete everything", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This is your final confirmation. All data will be permanently removed.")
            }
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section("Profile") {
            HStack(spacing: SakinahSpacing.md) {
                ZStack {
                    Circle()
                        .fill(SakinahColor.primaryLight)
                        .frame(width: 48, height: 48)
                    Text(String(appState.userName.prefix(1)).uppercased())
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(SakinahColor.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.userName)
                        .font(SakinahFont.headline)
                        .foregroundStyle(SakinahColor.textPrimary)
                    Text("Paired with \(appState.partnerName)")
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)
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
            Toggle("Daily prompt notification", isOn: $dailyPromptNotif)
                .tint(SakinahColor.primary)

            if dailyPromptNotif {
                DatePicker("Prompt time", selection: $promptTime, displayedComponents: .hourAndMinute)
                    .onChange(of: promptTime) { _, time in
                        Task { await NotificationService.shared.scheduleDailyPrompt(at: time) }
                    }
            }

            Toggle("Partner activity", isOn: $partnerActivityNotif)
                .tint(SakinahColor.primary)
            Toggle("Weekly reflection reminder", isOn: $weeklyReflectionNotif)
                .tint(SakinahColor.primary)

            if weeklyReflectionNotif {
                Picker("Reflection day", selection: $reflectionDay) {
                    Text("Friday").tag(6)
                    Text("Saturday").tag(7)
                    Text("Sunday").tag(1)
                }
            }

            Toggle("Milestone celebrations", isOn: $milestoneNotif)
                .tint(SakinahColor.primary)
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        Section("Subscription") {
            HStack {
                Text("Current plan")
                    .font(SakinahFont.body)
                Spacer()
                Text(SubscriptionService.shared.isPremium ? "Sakinah Premium ✨" : "Free")
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SubscriptionService.shared.isPremium ? SakinahColor.accent : SakinahColor.textSecondary)
            }

            if !SubscriptionService.shared.isPremium {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Text("Upgrade to Premium")
                            .font(SakinahFont.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.white)
                    }
                    .padding(SakinahSpacing.md)
                    .background(
                        LinearGradient(colors: [SakinahColor.primary, SakinahColor.primary.opacity(0.88)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(.rect(cornerRadius: SakinahRadius.small))
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                VStack(alignment: .leading, spacing: 6) {
                    premiumBenefit("✨ Themed conversation packs")
                    premiumBenefit("📊 Relationship trend insights")
                    premiumBenefit("💌 Scheduled love letters")
                    premiumBenefit("🎯 Shared goals & wishlists")
                }
            }
        }
    }

    private func premiumBenefit(_ text: String) -> some View {
        Text(text)
            .font(SakinahFont.bodySmall)
            .foregroundStyle(SakinahColor.textSecondary)
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
                Text("Your data is encrypted end-to-end")
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
            }

            Button {
                // Export data
            } label: {
                Label("Export My Data", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
            }

            Link("Privacy Policy", destination: URL(string: "https://sakinah.app/privacy")!)
            Link("Terms of Service", destination: URL(string: "https://sakinah.app/terms")!)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                    .foregroundStyle(SakinahColor.textTertiary)
            }

            Text("Made with 🤍 for the ummah")
                .font(SakinahFont.bodySmall)
                .foregroundStyle(SakinahColor.textSecondary)

            Button("Rate Sakinah") {
                requestReview()
            }

            Button {
                // Share sheet
            } label: {
                Label("Share Sakinah", systemImage: "square.and.arrow.up")
            }

            Link("Contact Support", destination: URL(string: "mailto:support@sakinah.app")!)
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
