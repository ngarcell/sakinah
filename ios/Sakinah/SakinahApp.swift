import SwiftUI
import SwiftData

@main
struct SakinahApp: App {
    @State private var appState = AppState()

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
                    SubscriptionService.shared.configure(apiKey: "appl_EFLrEgtHqDLISjcHIeDXBCVtYND")
                    await SubscriptionService.shared.loadProducts()
                    await SubscriptionService.shared.checkEntitlement()
                    appState.isSubscribed = SubscriptionService.shared.isPremium
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        // Check for day rollover
                        ContentService.shared.checkDateRollover()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }

    @Environment(\.scenePhase) private var scenePhase

    private func handleDeepLink(_ url: URL) {
        // sakinah://today/prompt or sakinah://today/dua
        guard url.scheme == "sakinah" else { return }
        // Deep link routing handled by ContentView
    }
}
