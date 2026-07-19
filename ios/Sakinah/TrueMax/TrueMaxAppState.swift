import Observation
import SwiftUI

enum TrueMaxRootTab: Int, CaseIterable, Identifiable {
    case home
    case scan
    case history
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .scan:
            return "Scan"
        case .history:
            return "History"
        case .settings:
            return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .home:
            return "house"
        case .scan:
            return "viewfinder"
        case .history:
            return "clock"
        case .settings:
            return "gearshape"
        }
    }

    var selectedSymbol: String {
        switch self {
        case .home:
            return "house.fill"
        case .scan:
            return "viewfinder"
        case .history:
            return "clock.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

enum TrueMaxAppearance: Int, CaseIterable, Identifiable {
    case dark

    var id: Int { rawValue }

    var title: String {
        "Dark"
    }

    var colorScheme: ColorScheme { .dark }
}

@Observable
@MainActor
final class TrueMaxAppState {
    private enum DefaultsKey {
        static let onboardingVersion = "truemax.onboardingVersion"
        static let cooldownDays = "truemax.cooldownDays"
        static let disclaimerAcknowledged = "truemax.disclaimerAcknowledged"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var selectedTab: TrueMaxRootTab = .home
    var isBootstrapping = true
    var presentsPaywall = false
    var scanRequestID = UUID()
    var onboardingRestartID = UUID()
    var disclaimerAcknowledged: Bool {
        didSet {
            defaults.set(disclaimerAcknowledged, forKey: DefaultsKey.disclaimerAcknowledged)
        }
    }
    // Kept as a compatibility value for existing state/tests; TrueMax is
    // intentionally dark-only and no longer exposes an appearance switcher.
    let appearance: TrueMaxAppearance = .dark
    var cooldownDays: Int {
        didSet {
            let normalized = min(max(cooldownDays, 1), 30)
            if normalized != cooldownDays {
                cooldownDays = normalized
            } else {
                defaults.set(normalized, forKey: DefaultsKey.cooldownDays)
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.disclaimerAcknowledged = defaults.bool(forKey: DefaultsKey.disclaimerAcknowledged)
        let storedCooldown = defaults.integer(forKey: DefaultsKey.cooldownDays)
        self.cooldownDays = storedCooldown == 0 ? 7 : min(max(storedCooldown, 1), 30)
    }

    var hasCompletedOnboarding: Bool {
        defaults.integer(forKey: DefaultsKey.onboardingVersion) >= TrueMaxBrand.onboardingVersion
    }

    var requiresMedicalDisclaimer: Bool {
        hasCompletedOnboarding && !disclaimerAcknowledged
    }

    func completeOnboarding() {
        defaults.set(TrueMaxBrand.onboardingVersion, forKey: DefaultsKey.onboardingVersion)
        selectedTab = .scan
    }

    func acknowledgeDisclaimer() {
        disclaimerAcknowledged = true
    }

    func startScan() {
        scanRequestID = UUID()
        selectedTab = .scan
    }

    func restartOnboarding() {
        defaults.removeObject(forKey: DefaultsKey.onboardingVersion)
        onboardingRestartID = UUID()
    }
}
