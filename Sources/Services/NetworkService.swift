import Foundation
import Network
import SystemConfiguration

final class NetworkService: ObservableObject, @unchecked Sendable {
    static let shared = NetworkService()
    
    @Published var availableServices: [String] = []
    @Published var activeService: String = ""
    @Published var currentDNS: [String] = []
    @Published var isLoading: Bool = false
    
    private let networksetupPath = "/usr/sbin/networksetup"
    private let appliedServersKey = "dns_widget_applied_servers"
    
    init() {
        refresh()
    }
    
    // MARK: - Refresh
    
    func refresh() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let services = self.getNetworkServices()
            let primary = self.getPrimaryService(from: services)
            DispatchQueue.main.async {
                self.availableServices = services
                self.activeService = primary
                self.currentDNS = self.readAppliedServers()
                self.isLoading = false
            }
        }
    }
    
    /// Re-applies the last chosen DNS silently, so a reboot or network change
    /// doesn't lose the setting or trigger an admin prompt.
    func restoreLastApplied() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let servers = self.readAppliedServers()
            guard !servers.isEmpty else { return }
            let service = self.getPrimaryService(from: self.getNetworkServices())
            _ = self.applyDNSServers(servers, for: service)
        }
    }
    
    // MARK: - Network Services
    
    func getNetworkServices() -> [String] {
        let output = runCommand(networksetupPath, ["-listallnetworkservices"])
        return output
            .components(separatedBy: "\n")
            .dropFirst()
            .filter { !$0.hasPrefix("*") && !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    private func getPrimaryService(from services: [String]) -> String {
        var preferredDevice = ""
        var currentPort = ""
        let ports = runCommand(networksetupPath, ["-listallhardwareports"])
        for line in ports.components(separatedBy: "\n") {
            if line.hasPrefix("Hardware Port:") {
                currentPort = line
                    .replacingOccurrences(of: #"^Hardware Port:\s*"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("Device:") {
                let device = line
                    .replacingOccurrences(of: #"^Device:\s*"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                if currentPort.localizedCaseInsensitiveContains("wi-fi") ||
                    currentPort.localizedCaseInsensitiveContains("ethernet") {
                    preferredDevice = device
                    break
                }
            }
        }
        
        let order = runCommand(networksetupPath, ["-listnetworkserviceorder"])
        var serviceName = ""
        for line in order.components(separatedBy: "\n") {
            if line.hasPrefix("(") {
                serviceName = line
                    .replacingOccurrences(of: #"^\(\d+\)\s*"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
            } else if !serviceName.isEmpty, line.contains("Device:") {
                let device = line
                    .replacingOccurrences(of: #"^.*Device:\s*([^\s)]+).*$"#, with: "$1", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                if !preferredDevice.isEmpty && device == preferredDevice {
                    return serviceName
                }
            }
        }
        
        return services.first ?? "Wi-Fi"
    }
    
    // MARK: - DNS Operations
    
    func setDNS(_ server: DNSServer, for service: String) -> Bool {
        let success = applyDNSServers(server.servers, for: service)
        if success {
            persistAppliedServers(server.servers)
            currentDNS = server.servers
        }
        return success
    }
    
    func resetDNS(for service: String) -> Bool {
        let success = applyDNSServers([], for: service)
        if success {
            persistAppliedServers([])
            currentDNS = []
        }
        return success
    }
    
    /// Applies DNS through the SystemConfiguration runtime store — no admin
    /// prompt. Falls back to networksetup (which may ask for permission) only
    /// when the runtime store is unavailable.
    private func applyDNSServers(_ servers: [String], for service: String) -> Bool {
        if let store = SCDynamicStoreCreate(nil, "com.dnswidget" as CFString, nil, nil),
           let serviceID = primaryServiceID(store) {
            let key = "State:/Network/Service/\(serviceID)/DNS" as CFString
            if servers.isEmpty {
                if SCDynamicStoreRemoveValue(store, key) {
                    return true
                }
            } else if SCDynamicStoreSetValue(store, key, ["ServerAddresses": servers] as CFDictionary) {
                return true
            }
        }
        
        let args = servers.isEmpty
            ? ["-setdnsservers", service, "Empty"]
            : ["-setdnsservers", service] + servers
        let result = runCommand(networksetupPath, args)
        return result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func primaryServiceID(_ store: SCDynamicStore) -> String? {
        guard let value = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString),
              let dict = value as? [String: Any],
              let id = dict["PrimaryService"] as? String else { return nil }
        return id
    }
    
    private func persistAppliedServers(_ servers: [String]) {
        UserDefaults.standard.set(servers, forKey: appliedServersKey)
    }
    
    private func readAppliedServers() -> [String] {
        UserDefaults.standard.stringArray(forKey: appliedServersKey) ?? []
    }
    
    // MARK: - Helpers
    
    private func runCommand(_ executable: String, _ arguments: [String]) -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
    
    func getCurrentDNSServer() -> DNSServer? {
        let servers = currentDNS
        guard !servers.isEmpty else { return nil }
        
        let allServers = StorageService.shared.allServers()
        for server in allServers {
            if servers.contains(server.primaryDNS) || servers.contains(server.secondaryDNS) {
                return server
            }
        }
        return nil
    }
}

extension WidgetDataManager {
    func syncFromNetwork(network: NetworkService, storage: StorageService) {
        let currentServer = network.getCurrentDNSServer()
        let data = SharedWidgetData(
            activeDNSName: currentServer?.name ?? "ISP Default",
            primaryDNS: network.currentDNS.first ?? "",
            secondaryDNS: network.currentDNS.count > 1 ? network.currentDNS[1] : "",
            networkService: network.activeService,
            lastUpdated: Date(),
            colorName: currentServer?.color.rawValue ?? "gray"
        )
        save(data)
    }
}