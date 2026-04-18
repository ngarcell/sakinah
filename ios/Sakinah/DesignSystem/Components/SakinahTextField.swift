import SwiftUI

struct SakinahTextField: View {
    let label: String
    var placeholder: String = ""
    @Binding var text: String
    var error: String? = nil
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
            Text(label)
                .font(SakinahFont.captionBold)
                .foregroundStyle(SakinahColor.textSecondary)
                .tracking(0.1)
                .textCase(.uppercase)

            TextField(placeholder, text: $text)
                .font(SakinahFont.body)
                .foregroundStyle(SakinahColor.textPrimary)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
                .focused($focused)
                .padding(.horizontal, SakinahSpacing.base)
                .frame(height: Theme.fieldHeight)
                .background(SakinahColor.backgroundSecondary)
                .clipShape(.rect(cornerRadius: SakinahRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: SakinahRadius.medium)
                        .stroke(borderColor, lineWidth: focused || error != nil ? 2 : 0)
                )
                .shadow(color: focused ? SakinahColor.primary.opacity(0.18) : .clear, radius: 16, x: 0, y: 0)
                .animation(.easeInOut(duration: 0.2), value: focused)
                .animation(.easeInOut(duration: 0.2), value: error)

            if let error {
                Text(error)
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.error)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var borderColor: Color {
        if error != nil { return SakinahColor.error }
        if focused { return SakinahColor.primary }
        return .clear
    }
}
