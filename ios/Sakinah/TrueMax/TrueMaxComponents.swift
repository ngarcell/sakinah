import SwiftUI

struct TrueMaxPageBackground: View {
    var body: some View {
        ZStack {
            TrueMaxPalette.background

            RadialGradient(
                colors: [TrueMaxPalette.accent.opacity(0.10), .clear],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}

struct TrueMaxPill: View {
    let icon: String
    let text: String
    var color: Color = TrueMaxPalette.accentLight

    var body: some View {
        Label(text, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 13)
            .frame(minHeight: 38)
            .background(color.opacity(0.09), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(color.opacity(0.65), lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
    }
}

struct TrueMaxIconCircle: View {
    let symbol: String
    var color: Color = TrueMaxPalette.accentLight
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.43, weight: .medium))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(TrueMaxPalette.cardRaised, in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(TrueMaxPalette.border, lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}

struct TrueMaxDisclosureRow: View {
    let icon: String
    let title: String
    var detail: String?
    var color: Color = TrueMaxPalette.accentLight
    var showsChevron = true

    var body: some View {
        HStack(spacing: 14) {
            TrueMaxIconCircle(symbol: icon, color: color)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TrueMaxPalette.textPrimary)

                if let detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(TrueMaxPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TrueMaxPalette.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: 58)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct MetricRangeCard: View {
    let metric: MetricKind
    let range: MetricRangeValue
    var compact = false
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading, spacing: compact ? 9 : 12) {
                HStack {
                    TrueMaxIconCircle(
                        symbol: metric.symbol,
                        color: TrueMaxPalette.accentLight,
                        size: compact ? 38 : 44
                    )

                    Spacer()

                    if action != nil {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(TrueMaxPalette.textTertiary)
                    }
                }

                Text(metric.title)
                    .font(compact ? .subheadline : .headline)
                    .foregroundStyle(TrueMaxPalette.textSecondary)

                Text(range.displayText)
                    .font(compact ? .title2.weight(.medium) : .largeTitle.weight(.medium))
                    .fontDesign(.rounded)
                    .monospacedDigit()
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if !compact {
                    Text(metric.summary)
                        .font(.footnote)
                        .foregroundStyle(TrueMaxPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .trueMaxCard()
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .accessibilityLabel("\(metric.title), \(range.accessibilityText)")
        .accessibilityHint(action == nil ? "" : "Opens measurement details")
    }
}

struct TrueMaxEmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            TrueMaxIconCircle(symbol: symbol, size: 58)

            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(TrueMaxPalette.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body)
                .foregroundStyle(TrueMaxPalette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .trueMaxCard()
    }
}

struct TrueMaxCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(TrueMaxPalette.textPrimary)
                .frame(width: 44, height: 44)
                .background(TrueMaxPalette.cardRaised.opacity(0.94), in: Circle())
                .overlay {
                    Circle().strokeBorder(TrueMaxPalette.border, lineWidth: 1)
                }
        }
        .accessibilityLabel("Close")
    }
}

struct TrueMaxLoadingView: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)
                .tint(TrueMaxPalette.accentLight)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(TrueMaxPalette.textPrimary)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(TrueMaxPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
    }
}
