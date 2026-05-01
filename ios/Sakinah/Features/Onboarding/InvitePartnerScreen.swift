import SwiftUI

struct InvitePartnerScreen: View {
    @Bindable var vm: OnboardingViewModel
    @State private var showShare = false
    @State private var orbit: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: SakinahSpacing.xl) {
                    pathPicker
                        .padding(.horizontal, SakinahSpacing.base)

                    if vm.invitePath == .starting {
                        startingPath.transition(.opacity.combined(with: .move(edge: .trailing)))
                    } else {
                        joiningPath.transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                .padding(.vertical, SakinahSpacing.xl)
                .animation(SakinahAnimation.spring, value: vm.invitePath)
            }

            SakinahButton(title: vm.invitePath == .starting ? "Keep going" : "Continue") {
                if vm.invitePath == .starting {
                    vm.advance(to: .coupleSetup)
                } else {
                    _ = vm.validateAndJoin()
                }
            }
            .padding(.horizontal, SakinahSpacing.base)
            .padding(.bottom, SakinahSpacing.base)
        }
    }

    private var header: some View {
        HStack {
            Button {
                HapticEngine.shared.fire(.tap)
                vm.advance(to: .welcome)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(SakinahColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(SakinahColor.surface)
                    .clipShape(Circle())
                    .sakinahShadow(.subtle)
            }
            .pressScale()
            Spacer()
            Text("Connect")
                .font(SakinahFont.headline)
                .foregroundStyle(SakinahColor.textPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, SakinahSpacing.base)
        .padding(.top, SakinahSpacing.sm)
    }

    private var pathPicker: some View {
        HStack(spacing: 0) {
            pathButton("I'm starting us", path: .starting)
            pathButton("I have a code", path: .joining)
        }
        .padding(4)
        .background(SakinahColor.backgroundSecondary)
        .clipShape(.capsule)
    }

    private func pathButton(_ title: String, path: InvitePath) -> some View {
        Button {
            HapticEngine.shared.fire(.select)
            vm.invitePath = path
        } label: {
            Text(title)
                .font(SakinahFont.captionBold)
                .foregroundStyle(vm.invitePath == path ? .white : SakinahColor.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        if vm.invitePath == path {
                            Capsule().fill(SakinahColor.primary)
                                .matchedGeometryEffect(id: "pathPill", in: pathNS)
                        }
                    }
                )
        }
        .animation(SakinahAnimation.spring, value: vm.invitePath)
    }

    @Namespace private var pathNS

    private var startingPath: some View {
        VStack(spacing: SakinahSpacing.xl) {
            orbitAnimation
                .frame(height: 160)

            VStack(spacing: SakinahSpacing.sm) {
                Text("Your invite code")
                    .font(SakinahFont.captionBold)
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .foregroundStyle(SakinahColor.textSecondary)

                HStack(spacing: SakinahSpacing.sm) {
                    ForEach(Array(vm.inviteCode.enumerated()), id: \.offset) { _, ch in
                        Text(String(ch))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(SakinahColor.primary)
                            .frame(width: 44, height: 56)
                            .background(SakinahColor.primaryLight)
                            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
                    }
                }
                .sakinahShadow(.subtle)
            }
            .padding(SakinahSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(SakinahColor.surface)
            .clipShape(.rect(cornerRadius: SakinahRadius.large))
            .sakinahShadow(.medium)
            .padding(.horizontal, SakinahSpacing.base)

            VStack(spacing: SakinahSpacing.sm) {
                SakinahButton(title: "Share code", icon: "square.and.arrow.up") {
                    showShare = true
                }
                SakinahButton(title: "Copy code", icon: "doc.on.doc", variant: .secondary) {
                    UIPasteboard.general.string = vm.inviteCode
                    HapticEngine.shared.fire(.success)
                }
            }
            .padding(.horizontal, SakinahSpacing.base)
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: ["I’d love to do this together. Use this code: \(vm.inviteCode)"])
                .presentationDetents([.medium])
        }
    }

    private var orbitAnimation: some View {
        ZStack {
            Circle().stroke(SakinahColor.divider, lineWidth: 1).frame(width: 140, height: 140)
            Circle().fill(SakinahColor.primary).frame(width: 18, height: 18)
                .offset(x: 70)
                .rotationEffect(.degrees(orbit))
                .glow(color: SakinahColor.primary, radius: 10, opacity: 0.5)
            Circle()
                .stroke(SakinahColor.accent, lineWidth: 2)
                .frame(width: 18, height: 18)
                .offset(x: 70)
                .rotationEffect(.degrees(orbit + 180))
                .glow(color: SakinahColor.accent, radius: 10, opacity: 0.4)
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                orbit = 360
            }
        }
    }

    private var joiningPath: some View {
        VStack(spacing: SakinahSpacing.xl) {
            VStack(spacing: SakinahSpacing.sm) {
                Text("Enter your partner's code")
                    .font(SakinahFont.title2)
                    .foregroundStyle(SakinahColor.textPrimary)
                Text("Use the code they shared with you.")
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            CodeInputField(code: $vm.joinCode, length: Constants.inviteCodeLength)
                .padding(.horizontal, SakinahSpacing.base)

            if let err = vm.joinError {
                Text(err)
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.error)
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct CodeInputField: View {
    @Binding var code: String
    let length: Int
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            HStack(spacing: SakinahSpacing.sm) {
                ForEach(0..<length, id: \.self) { i in
                    let chars = Array(code)
                    let char = i < chars.count ? String(chars[i]) : ""
                    let isActive = i == chars.count && focused
                    Text(char)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(SakinahColor.primary)
                        .frame(width: 48, height: 56)
                        .background(SakinahColor.backgroundSecondary)
                        .clipShape(.rect(cornerRadius: SakinahRadius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: SakinahRadius.medium)
                                .stroke(isActive ? SakinahColor.primary : Color.clear, lineWidth: 2)
                        )
                        .animation(.easeInOut(duration: 0.15), value: isActive)
                }
            }
            TextField("", text: $code)
                .textInputAutocapitalization(.characters)
                .keyboardType(.asciiCapable)
                .autocorrectionDisabled()
                .focused($focused)
                .opacity(0.01)
                .onChange(of: code) { _, new in
                    let filtered = String(new.uppercased().filter { Constants.inviteCodeAlphabet.contains($0) })
                    code = String(filtered.prefix(length))
                }
        }
        .onTapGesture { focused = true }
        .onAppear { focused = true }
    }
}
