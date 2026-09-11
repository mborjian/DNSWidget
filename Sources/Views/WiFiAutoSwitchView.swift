import SwiftUI

struct WiFiAutoSwitchView: View {
    @EnvironmentObject var storage: StorageService
    @EnvironmentObject var wifiMonitor: WiFiMonitor
    
    @State private var newSSID: String = ""
    @State private var selectedServerID: UUID?
    @State private var showAddRule = false
    
    var body: some View {
        VStack(spacing: 0) {
            ThinScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    SectionHeader(title: "Auto-Switch Rules")
                    
                    if wifiMonitor.networkRules.isEmpty {
                        EmptyState(
                            icon: "wifi",
                            title: "No rules configured",
                            subtitle: "Add rules to automatically switch DNS when joining Wi-Fi networks"
                        )
                    } else {
                        ForEach(wifiMonitor.networkRules.values.sorted(by: { $0.ssid < $1.ssid })) { rule in
                            ruleRow(rule)
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.top, DS.Spacing.md)
                .padding(.bottom, showAddRule ? 170 : 72)
            }
            .background(DS.Colors.bg)
        }
        .background(DS.Colors.bg)
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                if showAddRule {
                    addRuleForm
                }
                
                footer
            }
        }
    }
    
    // MARK: - Rule Row
    
    private func ruleRow(_ rule: WiFiMonitor.WiFiRule) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "wifi")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(rule.enabled ? .cyan : .gray)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.ssid)
                    .font(DS.Font.headline)
                    .foregroundStyle(DS.Colors.text)
                if let server = storage.allServers().first(where: { $0.id == rule.serverID }) {
                    Text("→ \(server.name) (\(server.primaryDNS))")
                        .font(DS.Font.monoSmall)
                        .foregroundStyle(DS.Colors.textTertiary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { rule.enabled },
                set: { _ in wifiMonitor.toggleRule(for: rule.ssid) }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .tint(.cyan)
            
            ActionDot(icon: "trash", color: DS.Colors.danger) {
                wifiMonitor.removeRule(for: rule.ssid)
            }
            .help("Delete rule")
        }
        .padding(DS.Spacing.sm + 2)
        .glassCard(cornerRadius: DS.Radius.md)
    }
    
    // MARK: - Add Rule Form
    
    private var addRuleForm: some View {
        VStack(spacing: DS.Spacing.sm) {
            Divider().overlay(DS.Colors.border)
            
            HStack(spacing: DS.Spacing.sm) {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("Network Name (SSID)")
                        .font(DS.Font.caption)
                        .foregroundStyle(DS.Colors.textTertiary)
                    TextField("e.g. Home-WiFi", text: $newSSID)
                        .textFieldStyle(.plain)
                        .font(DS.Font.body)
                        .padding(DS.Spacing.sm)
                        .background(DS.Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.sm)
                                .stroke(DS.Colors.border, lineWidth: 0.5)
                        )
                }
                
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("Use DNS")
                        .font(DS.Font.caption)
                        .foregroundStyle(DS.Colors.textTertiary)
                    Menu {
                        ForEach(storage.allServers()) { server in
                            Button(action: { selectedServerID = server.id }) {
                                HStack {
                                    Circle().fill(server.color.color).frame(width: 8, height: 8)
                                    Text(server.name)
                                    if selectedServerID == server.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            if let id = selectedServerID,
                               let server = storage.allServers().first(where: { $0.id == id }) {
                                Circle().fill(server.color.color).frame(width: 8, height: 8)
                                Text(server.name)
                                    .font(DS.Font.body)
                            } else {
                                Text("Select DNS")
                                    .font(DS.Font.body)
                                    .foregroundStyle(DS.Colors.textTertiary)
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8))
                        }
                        .padding(DS.Spacing.sm)
                        .background(DS.Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.sm)
                                .stroke(DS.Colors.border, lineWidth: 0.5)
                        )
                    }
                    .menuStyle(.borderlessButton)
                }
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.Colors.bgElevated)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        FooterIsland {
            HStack(spacing: DS.Spacing.sm) {
                Spacer()
                
                if showAddRule {
                    PillButton(title: "Cancel", icon: "xmark", color: .gray) {
                        showAddRule = false
                        newSSID = ""
                        selectedServerID = nil
                    }
                    
                    PillButton(title: "Add Rule", icon: "plus", color: DS.Colors.accent) {
                        addRule()
                    }
                    .opacity(canAddRule ? 1 : 0.4)
                    .disabled(!canAddRule)
                } else {
                    PillButton(title: "Add Rule", icon: "plus", color: .cyan) {
                        showAddRule = true
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var canAddRule: Bool {
        !newSSID.trimmingCharacters(in: .whitespaces).isEmpty && selectedServerID != nil
    }
    
    private func addRule() {
        guard canAddRule, let serverID = selectedServerID else { return }
        wifiMonitor.addRule(ssid: newSSID.trimmingCharacters(in: .whitespaces), serverID: serverID)
        newSSID = ""
        selectedServerID = nil
        showAddRule = false
    }
}
