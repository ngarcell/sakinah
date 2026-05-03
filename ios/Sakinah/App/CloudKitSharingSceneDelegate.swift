import CloudKit
import UIKit

final class CloudKitSharingAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = CloudKitSharingSceneDelegate.self
        return configuration
    }
}

final class CloudKitSharingSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(
        _: UIScene,
        willConnectTo _: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let shareMetadata = connectionOptions.cloudKitShareMetadata else { return }

        Task {
            try? await CloudKitService.shared.acceptShare(shareMetadata)
        }
    }

    func windowScene(
        _: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        Task {
            try? await CloudKitService.shared.acceptShare(cloudKitShareMetadata)
        }
    }
}
