import Foundation
import SwiftData
import SwiftUI

@main
struct SakinahApp: App {
    private struct ModelBootstrap {
        let container: ModelContainer
        let failureMessage: String?
    }

    @Environment(\.scenePhase) private var scenePhase

    @State private var appState = TrueMaxAppState()
    @State private var subscriptionService = SubscriptionService.shared

    private let modelBootstrap = Self.makeModelContainer()

    init() {
        TrueMaxAnalytics.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let failureMessage = modelBootstrap.failureMessage {
                    TrueMaxStorageUnavailableView(message: failureMessage)
                } else {
                    ContentView()
                }
            }
                .environment(appState)
                .environment(subscriptionService)
                .preferredColorScheme(.dark)
                .tint(TrueMaxPalette.accentLight)
                .task {
                    guard modelBootstrap.failureMessage == nil else {
                        appState.isBootstrapping = false
                        return
                    }
                    subscriptionService.loadSubscriptionState()
                    _ = await subscriptionService.preparePaywall(forceRefresh: false)
                    appState.isBootstrapping = false
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task {
                        await subscriptionService.refreshEntitlements()
                    }
                }
        }
        .modelContainer(modelBootstrap.container)
    }

    private static func makeModelContainer() -> ModelBootstrap {
        let schema = Schema([
            ScanRecord.self,
            StyleFavorite.self,
        ])

        do {
            let configuration = ModelConfiguration(
                "TrueMaxLocal",
                schema: schema,
                url: try localStoreURL(),
                allowsSave: true,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            return ModelBootstrap(container: container, failureMessage: nil)
        } catch {
            assertionFailure("TrueMax local store could not be opened: \(error)")
            let fallback = ModelConfiguration(
                "TrueMaxLocalFallback",
                schema: schema,
                isStoredInMemoryOnly: true,
                allowsSave: true,
                cloudKitDatabase: .none
            )

            do {
                let container = try ModelContainer(
                    for: schema,
                    configurations: [fallback]
                )
                return ModelBootstrap(
                    container: container,
                    failureMessage: "TrueMax could not open its protected local storage. No scan data was changed. Close and reopen the app; if the problem continues, restart your iPhone before trying again."
                )
            } catch {
                fatalError("TrueMax could not create a local model container: \(error)")
            }
        }
    }

    private static func localStoreURL() throws -> URL {
        let manager = FileManager.default
        guard let applicationSupport = manager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw TrueMaxStorageBootstrapError.applicationSupportUnavailable
        }

        let directory = applicationSupport.appendingPathComponent(
            "TrueMaxLocalData",
            isDirectory: true
        )
        try manager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        try manager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: directory.path
        )

        var protectedDirectory = directory
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try protectedDirectory.setResourceValues(resourceValues)

        return protectedDirectory.appendingPathComponent("TrueMaxLocal-v1.store")
    }
}

private enum TrueMaxStorageBootstrapError: LocalizedError {
    case applicationSupportUnavailable

    var errorDescription: String? {
        switch self {
        case .applicationSupportUnavailable:
            return "The protected Application Support directory is unavailable."
        }
    }
}

private struct TrueMaxStorageUnavailableView: View {
    let message: String

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            VStack(spacing: 20) {
                TrueMaxIconCircle(
                    symbol: "externaldrive.badge.exclamationmark",
                    color: TrueMaxPalette.caution,
                    size: 68
                )

                Text("Local storage unavailable")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Label(
                    "TrueMax will not run in a temporary mode or risk losing a scan.",
                    systemImage: "lock.shield"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TrueMaxPalette.textSecondary)
                .multilineTextAlignment(.center)
            }
            .padding(24)
            .trueMaxContentWidth()
        }
    }
}
