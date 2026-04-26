import SwiftUI

enum SakinahButtonVariant {
    case primary, secondary, ghost, accent
}

struct SakinahButton: View {
    let title: String
    var icon: String? = nil
    var variant: SakinahButtonVariant = .primary
    var isLoading: Bool = false
    var isFullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            HapticEngine.shared.fire(.tap)
            action()
        } label: {
            HStack(spacing: SakinahSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(foreground)
                } else {
                    if let icon {
                        Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(SakinahFont.headline)
                }
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, isFullWidth ? 0 : SakinahSpacing.xl)
            .background(background)
            .clipShape(.rect(cornerRadius: SakinahRadius.small))
            .sakinahShadow(variant == .primary || variant == .accent ? .medium : .subtle)
            .opacity(isLoading ? 0.9 : 1)
        }
        .pressScale()
        .disabled(isLoading)
    }

    private var height: CGFloat {
        variant == .ghost ? 44 : Theme.buttonHeight
    }

    @ViewBuilder
    private var background: some View {
        switch variant {
        case .primary:
            LinearGradient(
                colors: [SakinahColor.primary, SakinahColor.primary.opacity(0.88)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .accent:
            LinearGradient(
                colors: [SakinahColor.accent, SakinahColor.accentWarm],
                startPoint: .leading, endPoint: .trailing
            )
        case .secondary:
            SakinahColor.primaryLight
        case .ghost:
            Color.clear
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary, .accent: return .white
        case .secondary, .ghost: return SakinahColor.primary
        }
    }
}
