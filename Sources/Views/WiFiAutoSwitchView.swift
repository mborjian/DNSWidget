import SwiftUI

struct WiFiAutoSwitchView: View {
    @EnvironmentObject var storage: StorageService
    @EnvironmentObject var wifiMonitor: WiFiMonitor
    
    @State private var newSSID: String = ""
    @State private var selectedServerID: UUID?
    @State private var showAddRule = false
    
    var body: some View {
        VStack(spacing: 0) {
            currentNetworkCard
            
            ScrollView {
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
                .padding(DS.Spacing.md)
            }
            .background(DS.Colors.bg)
            
            Divider().overlay(DS.Colors.border)
            
            if showAddRule {
                addRuleForm
            }
            
            footer
        }
        .background(DS.Colors.bg)
    }
    
    // MARK: - Current Network Card
    
    private var currentNetworkCard: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "wifi")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.cyan)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Network")
                    .font(DS.Font.caption)
                    .foregroundStyle(DS.Colors.textTertiary)
                Text(wifiMonitor.currentSSID.isEmpty ? "Not connected to Wi-Fi" : wifiMonitor.currentSSID)
                    .font(DS.Font.headline)
                    .foregroundStyle(DS.Colors.text)
            }
            
            Spacer()
            
            if !wifiMonitor.currentSSID.isEmpty {
                if wifiMonitor.networkRules[wifiMonitor.currentSSID] != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.green)
                } else {
                    Button(action: {
                        newSSID = wifiMonitor.currentSSID
                        showAddRule = true
                    }) {
                        Label("Add Rule", systemImage: "plus")
                            .font(DS.Font.caption)
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, DS.Spacing.sm)
                            .padding(.vertical, DS.Spacing.xs)
                            .background(.cyan.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(DS.Spacing.md)
        .glassCard(cornerRadius: DS.Radius.lg)
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
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
            
            Button(action: { wifiMonitor.removeRule(for: rule.ssid) }) {
                Image(systemName: "trash")
                    .font(.system(size: 9))
                    .foregroundStyle(DS.Colors.danger)
            }
            .buttonStyle(.plain)
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
        HStack {
            Spacer()
            
            if showAddRule {
                Button("Cancel") {
                    showAddRule = false
                    newSSID = ""
                    selectedServerID = nil
                }
                .buttonStyle(.plain)
                .foregroundStyle(DS.Colors.textSecondary)
                .font(DS.Font.body)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(DS.Colors.card)
                .clipShape(Capsule())
                
                Button(action: addRule) {
                    HStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "plus")
                        Text("Add Rule")
                            .font(DS.Font.headline)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.sm)
                    .background(Capsule().fill(canAddRule ? DS.Colors.accentGradient : LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)))
                }
                .buttonStyle(.plain)
                .disabled(!canAddRule)
            } else {
                Button(action: { showAddRule = true }) {
                    Label("Add Rule", systemImage: "plus")
                        .font(DS.Font.caption)
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, DS.Spacing.sm + 2)
                        .padding(.vertical, DS.Spacing.xs + 1)
                        .background(.cyan.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.Colors.bgElevated)
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
