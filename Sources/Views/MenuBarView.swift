import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var storage: StorageService
    @EnvironmentObject var network: NetworkService
    @EnvironmentObject var latencyService: LatencyService
    
    @State private var presented: PresentedContent?
    @State private var toast: Toast?
    @State private var dropTargetID: UUID?
    
    private let visibleRowCount = 4
    private let rowHeight: CGFloat = 48
    
    private struct Toast: Identifiable {
        let id = UUID()
        let message: String
        let isError: Bool
    }
    
    var body: some View {
        Group {
            switch presented {
            case nil:
                mainContent
            case .addServer:
                AddEditDNSView(onClose: closePresented)
                    .environmentObject(storage)
            case .editServer(let server):
                AddEditDNSView(editing: server, onClose: closePresented)
                    .environmentObject(storage)
            case .settings:
                SettingsView(onClose: closePresented)
            }
        }
        .background(DS.Colors.bg)
        .background(MenuBarWindowAccessor())
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            GradientHeader(title: "DNS Widget", icon: "network")
            
            GradientDivider()
            
            serverList
            
            GradientDivider()
            
            footerBar
        }
        .frame(width: 360)
        .overlay(alignment: .top) {
            if let toast = toast {
                ToastMessage(text: toast.message, isError: toast.isError)
                    .padding(.top, DS.Spacing.sm)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            network.refresh()
        }
    }
    
    private enum PresentedContent: Identifiable {
        case addServer
        case editServer(DNSServer)
        case settings
        
        var id: String {
            switch self {
            case .addServer: return "addServer"
            case .editServer(let server): return "editServer-\(server.id)"
            case .settings: return "settings"
            }
        }
    }
    
    private struct ScrollableIfNeeded: ViewModifier {
        let count: Int
        let visibleRows: Int
        let rowHeight: CGFloat
        
        @ViewBuilder
        func body(content: Content) -> some View {
            if count > visibleRows {
                ScrollView {
                    content
                }
                .frame(height: CGFloat(visibleRows) * rowHeight)
            } else {
                content
            }
        }
    }
    
    private struct MenuBarWindowAccessor: NSViewRepresentable {
        func makeNSView(context: Context) -> NSView {
            let view = NSView()
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                view.window?.makeKey()
            }
            return view
        }
        
        func updateNSView(_ nsView: NSView, context: Context) {
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                nsView.window?.makeKey()
            }
        }
    }
    
    // MARK: - Server List
    
    private var serverList: some View {
        VStack(spacing: 2) {
            ForEach(displayServers) { server in
                DNSRow(server)
            }
        }
        .modifier(ScrollableIfNeeded(count: displayServers.count, visibleRows: visibleRowCount, rowHeight: rowHeight))
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.xs)
    }
    
    private var displayServers: [DNSServer] {
        let all = storage.allServers()
        var result: [DNSServer] = []
        if let active = all.first(where: { isActive($0) }) {
            result.append(active)
        }
        result.append(contentsOf: all.filter { $0.isPinned && !isActive($0) })
        result.append(contentsOf: all.filter { !$0.isPinned && !isActive($0) })
        return result
    }
    
    // MARK: - Footer
    
    private var footerBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            PillButton(title: "Add", icon: "plus", color: DS.Colors.accent) {
                presented = .addServer
            }
            
            PillButton(
                title: latencyService.isTesting ? "Testing..." : "Ping",
                icon: latencyService.isTesting ? "antenna.radiowaves.left.and.right" : "bolt.horizontal",
                color: latencyService.isTesting ? .cyan : .teal
            ) {
                latencyService.testAll(storage.allServers())
            }
            .disabled(latencyService.isTesting)
            
            Spacer()
            
            PillButton(title: "Auto", icon: "arrow.triangle.2.circlepath", color: DS.Colors.warning) {
                resetToAutomatic()
            }
            
            IconButton(icon: "gearshape") {
                presented = .settings
            }
            
            IconButton(icon: "arrow.clockwise") {
                withAnimation(.spring(response: 0.4)) {
                    network.refresh()
                }
            }
        }
        .padding(DS.Spacing.md)
    }
    
    // MARK: - DNS Row (inline)
    
    @ViewBuilder
    private func DNSRow(_ server: DNSServer) -> some View {
        DNSRowView(
            server: server,
            isActive: isActive(server),
            onSelect: { applyDNS(server) },
            onEdit: { presented = .editServer(server) },
            onTogglePinned: { storage.togglePinned(server) }
        )
        .draggable(server.id.uuidString)
        .dropDestination(for: String.self) { items, location in
            guard let idString = items.first,
                  let dragged = displayServers.first(where: { $0.id.uuidString == idString }),
                  dragged.id != server.id else { return false }
            let before = location.y < rowHeight / 2
            storage.moveItem(dragged, relativeTo: server, after: !before)
            return true
        } isTargeted: { targeted in
            if targeted {
                dropTargetID = server.id
            } else if dropTargetID == server.id {
                dropTargetID = nil
            }
        }
        .overlay {
            if dropTargetID == server.id {
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .stroke(DS.Colors.accent.opacity(0.8), lineWidth: 1.5)
            }
        }
    }
    
    // MARK: - Presented content
    
    private func closePresented() {
        presented = nil
    }
    
    // MARK: - Helpers
    
    private func isActive(_ server: DNSServer) -> Bool {
        network.currentDNS.contains(server.primaryDNS)
    }
    
    private func applyDNS(_ server: DNSServer) {
        let success = network.setDNS(server, for: network.activeService)
        showToast(
            message: success ? "\(server.name) applied" : "Failed to apply DNS",
            isError: !success
        )
        WidgetDataManager.shared.syncFromNetwork(network: network, storage: storage)
    }
    
    private func resetToAutomatic() {
        let success = network.resetDNS(for: network.activeService)
        showToast(
            message: success ? "Reset to automatic" : "Failed to reset",
            isError: !success
        )
        WidgetDataManager.shared.syncFromNetwork(network: network, storage: storage)
    }
    
    private func showToast(message: String, isError: Bool) {
        withAnimation(.spring(response: 0.4)) {
            toast = Toast(message: message, isError: isError)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.3)) {
                toast = nil
            }
        }
    }
}
