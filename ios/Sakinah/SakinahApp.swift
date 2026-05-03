import SwiftUI
import SwiftData

@main
struct SakinahApp: App {
    @UIApplicationDelegateAdaptor(CloudKitSharingAppDelegate.self) private var appDelegate
    @State private var appState = AppState()
    @State private var subscriptionService = SubscriptionService.shared
    @AppStorage("selectedAppearance") private var selectedAppearance = AppAppearanceMode.system.rawValue

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
                .preferredColorScheme(currentAppearance.colorScheme)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .task {
                    await bootstrapApp()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await handleActiveScene() }
                    }
                }
                .onChange(of: subscriptionService.currentTier) { _, tier in
                    Task {
                        appState.handleSubscriptionState(isPremium: tier == .premium)

                        if tier == .premium {
                            await CloudKitService.shared.syncIfPossible(
                                appState: appState,
                                context: sharedModelContainer.mainContext
                            )
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .sakinahPendingShareChanged)) { _ in
                    appState.notePendingShareDetected()

                    Task {
                        await CloudKitService.shared.syncIfPossible(
                            appState: appState,
                            context: sharedModelContainer.mainContext
                        )
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }

    @Environment(\.scenePhase) private var scenePhase

    private var currentAppearance: AppAppearanceMode {
        AppAppearanceMode(rawValue: selectedAppearance) ?? .system
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "sakinah" else { return }
    }

    private func bootstrapApp() async {
        subscriptionService.loadSubscriptionState()
        appState.handleSubscriptionState(isPremium: subscriptionService.isPremium)

        if CloudKitService.shared.hasPendingAcceptedShare {
            appState.notePendingShareDetected()
        }

        await CloudKitService.shared.syncIfPossible(
            appState: appState,
            context: sharedModelContainer.mainContext
        )
    }

    private func handleActiveScene() async {
        ContentService.shared.checkDateRollover()
        await subscriptionService.refreshEntitlements()
        appState.handleSubscriptionState(isPremium: subscriptionService.isPremium)

        if CloudKitService.shared.hasPendingAcceptedShare {
            appState.notePendingShareDetected()
        }

        await CloudKitService.shared.syncIfPossible(
            appState: appState,
            context: sharedModelContainer.mainContext
        )
    }
}
