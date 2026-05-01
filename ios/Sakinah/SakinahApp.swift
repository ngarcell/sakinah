import SwiftUI
import SwiftData

@main
struct SakinahApp: App {
    @State private var appState = AppState()
    @State private var subscriptionService = SubscriptionService.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Couple.self,
            DailyPrompt.self,
            PromptResponse.self,
            CheckIn.self,
            WeeklyReflection.self,
            Memory.self,
            Lesson.self,
            JournalEntry.self,
            LoveLetter.self,
            SharedGoal.self,
            WishItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .tint(SakinahColor.primary)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .task {
                    subscriptionService.loadSubscriptionState()
                    appState.isSubscribed = subscriptionService.isPremium
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        ContentService.shared.checkDateRollover()
                        Task {
                            await subscriptionService.refreshEntitlements()
                            appState.isSubscribed = subscriptionService.isPremium
                        }
                    }
                }
                .onChange(of: subscriptionService.currentTier) { _, tier in
                    appState.isSubscribed = tier == .premium
                }
        }
        .modelContainer(sharedModelContainer)
    }

    @Environment(\.scenePhase) private var scenePhase

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "sakinah" else { return }
    }
}
