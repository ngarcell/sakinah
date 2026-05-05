import SwiftUI

enum MainTab: Int, CaseIterable {
    case today, us, learn, ours

    var title: String {
        switch self {
        case .today: return "Today"
        case .us: return "Us"
        case .learn: return "Learn"
        case .ours: return "Ours"
        }
    }
    var icon: String {
        switch self {
        case .today: return "sun.max.fill"
        case .us: return "heart.circle.fill"
        case .learn: return "book.closed.fill"
        case .ours: return "square.grid.2x2.fill"
        }
    }
}

struct MainTabView: View {
    @State private var showSettings = false
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
        ZStack(alignment: .bottom) {
            Group {
                switch appState.selectedTab {
                case .today: TodayView()
                case .us: UsView()
                case .learn: LearnView()
                case .ours: OursView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SakinahColor.background.ignoresSafeArea())

            CustomTabBar(selected: selectedBinding, showSettings: $showSettings)
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.bottom, SakinahSpacing.sm)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: invitePromptBinding) {
            PartnerInvitePromptView()
        }
        .sheet(item: paywallBinding) { entryPoint in
            SakinahPaywallView(entryPoint: entryPoint, isMandatory: false)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selected: MainTab
    @Binding var showSettings: Bool
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button {
                    HapticEngine.shared.fire(.tap)
                    withAnimation(SakinahAnimation.spring) { selected = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .symbolEffect(.bounce, value: selected == tab)
                        Text(tab.title)
                            .font(SakinahFont.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(selected == tab ? SakinahColor.primary : SakinahColor.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SakinahSpacing.sm)
                    .background(
                        ZStack {
                            if selected == tab {
                                RoundedRectangle(cornerRadius: SakinahRadius.medium)
                                    .fill(SakinahColor.primaryLight)
                                    .matchedGeometryEffect(id: "tabPill", in: ns)
                            }
                        }
                    )
                }
                .pressScale(0.94)
            }

            // Settings gear
            Button {
                HapticEngine.shared.fire(.tap)
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SakinahColor.textTertiary)
                    .frame(width: 40, height: 40)
            }
            .pressScale(0.94)
        }
        .padding(6)
        .background(
            SakinahColor.surface
                .clipShape(.rect(cornerRadius: SakinahRadius.large))
                .sakinahShadow(.medium)
        )
    }
}
