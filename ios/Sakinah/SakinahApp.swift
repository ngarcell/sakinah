import SwiftUI
import SwiftData

@main
struct SakinahApp: App {
    @UIApplicationDelegateAdaptor(CloudKitSharingAppDelegate.self) private var appDelegate
    @State private var appState = AppState()
    @State private var subscriptionService = SubscriptionService.shared
    @AppStorage("selectedAppearance") private var selectedAppearance = AppAppearanceMode.system.rawValue

    private static let storeFilename = "default.store"

    var sharedModelContainer: ModelContainer = Self.makeModelContainer()

    private static var appSchema: Schema {
        Schema([
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
            OnboardingDraft.self,
        ])
    }

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
                            persistPremiumUnlockStateIfNeeded()
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

    private static func makeModelContainer() -> ModelContainer {
        let schema = appSchema
        let storeURL = defaultStoreURL()
        let primaryConfiguration = ModelConfiguration(
            "Sakinah",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [primaryConfiguration])
        } catch {
            print("SwiftData store load failed, attempting recovery: \(error)")
            backupAndResetStore(at: storeURL)

            do {
                return try ModelContainer(for: schema, configurations: [primaryConfiguration])
            } catch {
                print("SwiftData store recovery failed, falling back to in-memory container: \(error)")

                let fallbackConfiguration = ModelConfiguration(
                    "SakinahInMemory",
                    schema: schema,
                    isStoredInMemoryOnly: true,
                    allowsSave: true,
                    groupContainer: .none,
                    cloudKitDatabase: .none
                )

                do {
                    return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
                } catch {
                    fatalError("Could not create any ModelContainer: \(error)")
                }
            }
        }
    }

    private static func defaultStoreURL() -> URL {
        let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true)
        return appSupportDirectory.appendingPathComponent(storeFilename)
    }

    private static func backupAndResetStore(at storeURL: URL) {
        let fileManager = FileManager.default
        let recoveryRoot = storeURL.deletingLastPathComponent().appendingPathComponent("StoreRecovery", isDirectory: true)
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let recoveryDirectory = recoveryRoot.appendingPathComponent(timestamp, isDirectory: true)

        try? fileManager.createDirectory(at: recoveryDirectory, withIntermediateDirectories: true)

        for suffix in ["", "-shm", "-wal"] {
            let sourceURL = URL(fileURLWithPath: storeURL.path + suffix)
            guard fileManager.fileExists(atPath: sourceURL.path) else { continue }

            let destinationURL = recoveryDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            try? fileManager.removeItem(at: destinationURL)
            try? fileManager.moveItem(at: sourceURL, to: destinationURL)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "sakinah" else { return }
    }

    private func bootstrapApp() async {
        subscriptionService.loadSubscriptionState()
        appState.handleSubscriptionState(isPremium: subscriptionService.isPremium)
        persistPremiumUnlockStateIfNeeded()

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
        persistPremiumUnlockStateIfNeeded()

        if CloudKitService.shared.hasPendingAcceptedShare {
            appState.notePendingShareDetected()
        }

        await CloudKitService.shared.syncIfPossible(
            appState: appState,
            context: sharedModelContainer.mainContext
        )
    }

    private func persistPremiumUnlockStateIfNeeded() {
        guard subscriptionService.isPremium,
              appState.currentUser?.requiresInitialSubscriptionUnlock == true else { return }

        appState.currentUser?.requiresInitialSubscriptionUnlock = false
        appState.currentUser?.hasSeenInitialSubscriptionPaywall = true
        appState.currentUser?.touch()
        try? sharedModelContainer.mainContext.save()
    }
}
