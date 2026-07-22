import SwiftUI

struct TrueMaxMainTabView: View {
    @Environment(TrueMaxAppState.self) private var appState
    @Environment(TrueMaxMarketingWalkthroughController.self) private var demo

    var body: some View {
        @Bindable var appState = appState

        ZStack {
            TabView(selection: $appState.selectedTab) {
                NavigationStack {
                    TrueMaxHomeView()
                }
                .tag(TrueMaxRootTab.home)
                .tabItem {
                    Label(
                        TrueMaxRootTab.home.title,
                        systemImage: appState.selectedTab == .home
                            ? TrueMaxRootTab.home.selectedSymbol
                            : TrueMaxRootTab.home.symbol
                    )
                }

            NavigationStack {
                TrueMaxScanRootView()
            }
            .tag(TrueMaxRootTab.scan)
            .tabItem {
                Label(
                    TrueMaxRootTab.scan.title,
                    systemImage: TrueMaxRootTab.scan.symbol
                )
            }

            NavigationStack {
                TrueMaxHistoryView()
            }
            .tag(TrueMaxRootTab.history)
            .tabItem {
                Label(
                    TrueMaxRootTab.history.title,
                    systemImage: appState.selectedTab == .history
                        ? TrueMaxRootTab.history.selectedSymbol
                        : TrueMaxRootTab.history.symbol
                )
            }

            NavigationStack {
                TrueMaxSettingsView()
            }
            .tag(TrueMaxRootTab.settings)
            .tabItem {
                Label(
                    TrueMaxRootTab.settings.title,
                    systemImage: appState.selectedTab == .settings
                        ? TrueMaxRootTab.settings.selectedSymbol
                        : TrueMaxRootTab.settings.symbol
                )
            }
            }
            .tint(TrueMaxPalette.accentLight)
            .toolbarBackground(TrueMaxPalette.backgroundRaised, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .onAppear {
                TrueMaxAnalytics.shared.screen("main tabs", properties: [
                    "selected_tab": appState.selectedTab.title
                ])
            }
            .onChange(of: demo.phase) { _, phase in
                switch phase {
                case .home, .homeScroll, .styles, .styleCategory, .stylePreview, .styleFavorite, .finished:
                    appState.selectedTab = .home
                case .scanChecklist, .scanCapture, .scanProcessing, .scanResult, .resultScroll, .actionPlan, .actionPlanAll:
                    appState.selectedTab = .scan
                case .history, .historySelect, .historyFirst, .historySecond, .historyCompare, .historyScroll:
                    appState.selectedTab = .history
                case .idle:
                    break
                }
            }

            TrueMaxMarketingPlaybackOverlay()
        }
    }
}
