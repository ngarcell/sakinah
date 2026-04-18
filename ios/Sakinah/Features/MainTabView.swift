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
        case .ours: return "leaf.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selected: MainTab = .today
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .today: TodayPlaceholderView()
                case .us: UsPlaceholderView()
                case .learn: LearnPlaceholderView()
                case .ours: OursPlaceholderView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SakinahColor.background.ignoresSafeArea())

            CustomTabBar(selected: $selected)
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.bottom, SakinahSpacing.sm)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selected: MainTab
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
        }
        .padding(6)
        .background(
            SakinahColor.surface
                .clipShape(.rect(cornerRadius: SakinahRadius.large))
                .sakinahShadow(.medium)
        )
    }
}

private struct TodayPlaceholderView: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)
                    Text("Assalamu alaikum,\n\(appState.currentUser?.name ?? "friend") 🌙")
                        .font(SakinahFont.title1)
                        .foregroundStyle(SakinahColor.textPrimary)
                }
                .padding(.horizontal, SakinahSpacing.base)

                SakinahCard(elevated: true) {
                    VStack(alignment: .leading, spacing: SakinahSpacing.md) {
                        SakinahBadge(text: "Today's Prompt", icon: "sparkles",
                                     color: SakinahColor.accent, tintedBackground: SakinahColor.accentLight)
                        Text(ContentService.shared.todaysPrompt().text)
                            .font(SakinahFont.title3)
                            .foregroundStyle(SakinahColor.textPrimary)
                            .lineSpacing(3)
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(SakinahColor.textTertiary)
                            Text("Reveals when you both answer")
                                .font(SakinahFont.caption)
                                .foregroundStyle(SakinahColor.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)

                Text("Coming next")
                    .font(SakinahFont.captionBold)
                    .foregroundStyle(SakinahColor.textSecondary)
                    .tracking(0.4).textCase(.uppercase)
                    .padding(.horizontal, SakinahSpacing.base)

                VStack(spacing: SakinahSpacing.md) {
                    comingSoon(icon: "heart.text.square.fill", title: "Daily check-in", subtitle: "How are you feeling today?")
                    comingSoon(icon: "moon.stars.fill", title: "Du'a of the day", subtitle: "Arabic, English, transliteration")
                    comingSoon(icon: "leaf.fill", title: "Your wellness garden", subtitle: "Watch it grow with every moment")
                }
                .padding(.horizontal, SakinahSpacing.base)

                Spacer(minLength: 100)
            }
            .padding(.top, SakinahSpacing.lg)
        }
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 5 { return "Late night" }
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        if h < 21 { return "Good evening" }
        return "Good night"
    }

    private func comingSoon(icon: String, title: String, subtitle: String) -> some View {
        SakinahCard {
            HStack(spacing: SakinahSpacing.base) {
                ZStack {
                    Circle().fill(SakinahColor.primaryLight).frame(width: 44, height: 44)
                    Image(systemName: icon).foregroundStyle(SakinahColor.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(SakinahFont.headline).foregroundStyle(SakinahColor.textPrimary)
                    Text(subtitle).font(SakinahFont.caption).foregroundStyle(SakinahColor.textSecondary)
                }
                Spacer()
                SakinahBadge(text: "Soon")
            }
        }
    }
}

private struct UsPlaceholderView: View {
    var body: some View {
        SakinahEmptyState(
            icon: "heart.circle",
            title: "Your story together",
            message: "Shared memories, milestones, and the daily prompts you answer as a couple will live here."
        )
    }
}

private struct LearnPlaceholderView: View {
    var body: some View {
        SakinahEmptyState(
            icon: "book.closed",
            title: "Learn together",
            message: "Short lessons on love, faith, and growing in sakinah — coming soon."
        )
    }
}

private struct OursPlaceholderView: View {
    var body: some View {
        SakinahEmptyState(
            icon: "leaf",
            title: "Your garden",
            message: "Shared goals, du'as, and the wellness garden you tend together."
        )
    }
}
