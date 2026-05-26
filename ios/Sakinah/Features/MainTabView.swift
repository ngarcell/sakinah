import SwiftUI

enum MainTab: Int, CaseIterable, Hashable {
    case today, us, learn, ours, settings

    var title: String {
        switch self {
        case .today: return "Today"
        case .us: return "Us"
        case .learn: return "Learn"
        case .ours: return "Ours"
        case .settings: return "Settings"
        }
    }

    var selectedIcon: String {
        switch self {
        case .today: return "sun.max.fill"
        case .us: return "leaf.fill"
        case .learn: return "book.fill"
        case .ours: return "heart.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var icon: String {
        switch self {
        case .today: return "sun.max"
        case .us: return "leaf"
        case .learn: return "book"
        case .ours: return "heart"
        case .settings: return "gearshape"
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    private var selectedBinding: Binding<MainTab> {
        Binding(
            get: { appState.selectedTab },
            set: { appState.selectedTab = $0 }
        )
    }

    private var invitePromptBinding: Binding<Bool> {
        Binding(
            get: { appState.showPartnerInvitePrompt },
            set: { appState.showPartnerInvitePrompt = $0 }
        )
    }

    private var paywallBinding: Binding<SakinahPaywallEntryPoint?> {
        Binding(
            get: { appState.presentedPaywallEntryPoint },
            set: { appState.presentedPaywallEntryPoint = $0 }
        )
    }

    var body: some View {
        TabView(selection: selectedBinding) {
            TodayView()
                .tabItem { tabLabel(.today) }
                .tag(MainTab.today)

            UsView()
                .tabItem { tabLabel(.us) }
                .tag(MainTab.us)

            LearnView()
                .tabItem { tabLabel(.learn) }
                .tag(MainTab.learn)

            OursView()
                .tabItem { tabLabel(.ours) }
                .tag(MainTab.ours)

            SettingsView()
                .tabItem { tabLabel(.settings) }
                .tag(MainTab.settings)
        }
        .tint(SakinahColor.primary)
        .background(SakinahColor.background.ignoresSafeArea())
        .sheet(isPresented: invitePromptBinding) {
            PartnerInvitePromptView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: paywallBinding) { entryPoint in
            SakinahPaywallView(entryPoint: entryPoint, isMandatory: false)
        }
    }

    private func tabLabel(_ tab: MainTab) -> some View {
        let icon = appState.selectedTab == tab ? tab.selectedIcon : tab.icon
        return Label(tab.title, systemImage: icon)
    }
}
