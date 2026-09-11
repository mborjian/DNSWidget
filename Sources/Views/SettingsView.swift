import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var storage: StorageService
    @EnvironmentObject var wifiMonitor: WiFiMonitor
    @EnvironmentObject var launchAtLogin: LaunchAtLoginService
    var onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Settings", icon: "gearshape.fill", onClose: onClose)
            
            Divider().overlay(DS.Colors.border)
            
            launchRow
            
            Divider().overlay(DS.Colors.border)
            
            WiFiAutoSwitchView()
        }
        .frame(width: DS.Layout.pageWidth, height: DS.Layout.pageHeight)
        .background(DS.Colors.bg)
        .onExitCommand {
            onClose()
        }
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.async {
                (NSApp.keyWindow ?? NSApp.windows.first(where: { $0.isVisible }))?.makeKey()
            }
        }
    }
    
    // MARK: - Launch at Login
    
    private var launchRow: some View {
        HStack {
            Image(systemName: "power")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.green)
                .frame(width: 16)
            Text("Launch at Login")
                .font(DS.Font.body)
                .foregroundStyle(DS.Colors.text)
            Spacer()
            Toggle("", isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { _ in launchAtLogin.toggle() }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .tint(.green)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(DS.Colors.bg)
    }
}