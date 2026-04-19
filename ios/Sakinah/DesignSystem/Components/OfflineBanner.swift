import SwiftUI
import Network

struct OfflineBanner: View {
    @State private var isOnline = true

    var body: some View {
        Group {
            if !isOnline {
                HStack(spacing: SakinahSpacing.sm) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 12))
                    Text("Offline — changes will sync when connected")
                        .font(SakinahFont.caption)
                }
                .foregroundStyle(SakinahColor.textPrimary)
                .padding(.horizontal, SakinahSpacing.md)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(SakinahColor.warning.opacity(0.15))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(SakinahAnimation.gentle, value: isOnline)
        .task {
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "network-monitor")
            monitor.pathUpdateHandler = { path in
                Task { @MainActor in
                    isOnline = path.status == .satisfied
                }
            }
            monitor.start(queue: queue)
        }
    }
}
