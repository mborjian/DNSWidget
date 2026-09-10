import Foundation
import Network
import SwiftUI

final class WiFiMonitor: ObservableObject, @unchecked Sendable {
    static let shared = WiFiMonitor()
    
    @Published var currentSSID: String = ""
    @Published var isMonitoring = false
    
    @Published var networkRules: [String: WiFiRule] = [:]
    
    private var monitor: NWPathMonitor?
    private var lastSSID: String = ""
    private let storage = StorageService.shared
    private let networkService = NetworkService.shared
    
    private let storageKey = "dns_widget_wifi_rules"

    
    struct WiFiRule: Codable, Identifiable, Hashable {
        var id = UUID()
        var ssid: String
        var serverID: UUID
        var enabled: Bool = true
    }
    
    // MARK: - Persistence
    
    init() {
        loadRules()
    }
    
    private func loadRules() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: WiFiRule].self, from: data) else { return }
        networkRules = decoded
    }
    
    func saveRules() {
        guard let data = try? JSONEncoder().encode(networkRules) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    // MARK: - Rules Management
    
    func addRule(ssid: String, serverID: UUID) {
        let rule = WiFiRule(ssid: ssid, serverID: serverID)
        networkRules[ssid] = rule
        saveRules()
    }
    
    func removeRule(for ssid: String) {
        networkRules.removeValue(forKey: ssid)
        saveRules()
    }
    
    func toggleRule(for ssid: String) {
        guard var rule = networkRules[ssid] else { return }
        rule.enabled.toggle()
        networkRules[ssid] = rule
        saveRules()
    }
    
    func server(for ssid: String) -> DNSServer? {
        guard let rule = networkRules[ssid], rule.enabled else { return nil }
        return storage.allServers().first { $0.id == rule.serverID }
    }
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "com.dnswidget.wifimonitor")
        
        monitor?.pathUpdateHandler = { [weak self] _ in
            guard let self = self else { return }
            
            let newSSID = self.getWiFiSSID()
            DispatchQueue.main.async {
                self.currentSSID = newSSID
                
                if !newSSID.isEmpty && newSSID != self.lastSSID {
                    self.lastSSID = newSSID
                    self.handleNetworkChange(ssid: newSSID)
                }
            }
        }
        
        monitor?.start(queue: queue)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let ssid = self.getWiFiSSID()
            DispatchQueue.main.async {
                self.currentSSID = ssid
                self.lastSSID = ssid
            }
        }
    }
    
    func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
        isMonitoring = false
    }
    
    // MARK: - Auto-Switch
    
    private func handleNetworkChange(ssid: String) {
        let service = networkService.activeService
        
        if let server = server(for: ssid) {
            let success = networkService.setDNS(server, for: service)
            
            #if DEBUG
            print("[WiFiMonitor] Network changed to \"\(ssid)\", applied \(server.name): \(success)")
            #endif
        } else {
            networkService.restoreLastApplied()
        }
        
        WidgetDataManager.shared.syncFromNetwork(network: networkService, storage: storage)
    }
    
    // MARK: - SSID Detection
    
    private func getWiFiSSID() -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | grep ' SSID:' | awk '{print $2}'"]
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let ssid = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return ssid.isEmpty ? getSSIDFallback() : ssid
        } catch {
            return getSSIDFallback()
        }
    }
    
    private func getSSIDFallback() -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "system_profiler SPAirPortDataType 2>/dev/null | grep 'Current Network Information' -A 5 | grep 'SSID' | head -1 | sed 's/.*: //'"]
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            return ""
        }
    }
}
