import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var storage: StorageService
    @EnvironmentObject var wifiMonitor: WiFiMonitor
    @EnvironmentObject var launchAtLogin: LaunchAtLoginService
    var onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider().overlay(DS.Colors.border)
            
            launchRow
            
            Divider().overlay(DS.Colors.border)
            
            WiFiAutoSwitchView()
        }
        .frame(width: 360, height: 520)
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
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.gray, .gray.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 32, height: 32)
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(DS.Font.title)
                    .foregroundStyle(DS.Colors.text)
                Text("Launch behavior and Wi-Fi rules")
                    .font(DS.Font.caption)
                    .foregroundStyle(DS.Colors.textTertiary)
            }
            
            Spacer()
            
            Button(action: { onClose() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(DS.Colors.card))
            }
            .buttonStyle(.plain)
        }
        .padding(DS.Spacing.lg)
        .background(DS.Colors.bgElevated)
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