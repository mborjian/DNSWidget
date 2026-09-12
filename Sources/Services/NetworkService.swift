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
            let actual = self.resolvedDNSServers(self.makeStore())
            DispatchQueue.main.async {
                self.availableServices = services
                self.activeService = primary
                self.currentDNS = actual
                self.isLoading = false
            }
        }
    }
    
    func refreshCurrentDNS(after delay: TimeInterval = 0) {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            let actual = self.resolvedDNSServers(self.makeStore())
            DispatchQueue.main.async {
                guard self.currentDNS != actual else { return }
                self.currentDNS = actual
                WidgetDataManager.shared.syncFromNetwork(network: self, storage: StorageService.shared)
            }
        }
    }
    
    func restoreLastApplied() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let servers = self.readAppliedServers()
            guard !servers.isEmpty else { return }
            let service = self.getPrimaryService(from: self.getNetworkServices())
            _ = self.applyDNSServers(servers, for: service)
            self.refreshCurrentDNS(after: 0.4)
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
        let store = makeStore()
        let primary = primaryState(store)
        
        if let id = primary.serviceID, let name = serviceName(forID: id) {
            return name
        }
        
        if let device = primary.interface, let name = serviceName(forDevice: device) {
            return name
        }
        
        return services.first ?? "Wi-Fi"
    }
    
    private func makeStore() -> SCDynamicStore? {
        SCDynamicStoreCreate(nil, "com.dnswidget" as CFString, nil, nil)
    }
    
    private struct NetworkServiceEntry {
        let id: String
        let name: String
        let device: String?
    }
    
    private func networkServiceEntries() -> [NetworkServiceEntry] {
        guard let prefs = SCPreferencesCreate(nil, "com.dnswidget" as CFString, nil),
              let raw = SCNetworkServiceCopyAll(prefs),
              let services = raw as? [SCNetworkService] else { return [] }
        
        return services.compactMap { service in
            guard let id = SCNetworkServiceGetServiceID(service) as String?,
                  let name = SCNetworkServiceGetName(service) as String? else { return nil }
            return NetworkServiceEntry(id: id, name: name, device: bsdName(of: service))
        }
    }
    
    private func bsdName(of service: SCNetworkService) -> String? {
        guard let interface = SCNetworkServiceGetInterface(service),
              let name = SCNetworkInterfaceGetBSDName(interface) as String? else { return nil }
        return name
    }
    
    private func serviceName(forID id: String) -> String? {
        networkServiceEntries().first { $0.id == id }?.name
    }
    
    private func serviceName(forDevice device: String) -> String? {
        networkServiceEntries().first { $0.device == device }?.name
    }
    
    private func serviceID(for name: String) -> String? {
        networkServiceEntries().first { $0.name == name }?.id
    }
    
    // MARK: - DNS Operations
    
    func setDNS(_ server: DNSServer, for service: String) -> Bool {
        let success = applyDNSServers(server.servers, for: service)
        if success {
            persistAppliedServers(server.servers)
            currentDNS = server.servers
        }
        refreshCurrentDNS(after: 0.4)
        return success
    }
    
    func resetDNS(for service: String) -> Bool {
        let success = applyDNSServers([], for: service)
        if success {
            persistAppliedServers([])
            currentDNS = []
        }
        refreshCurrentDNS(after: 0.4)
        return success
    }
    
    func removeAllAndReset() {
        for service in getNetworkServices() {
            _ = applyDNSServers([], for: service)
        }
        persistAppliedServers([])
        currentDNS = []
    }
    
    private func applyDNSServers(_ servers: [String], for service: String) -> Bool {
        let store = makeStore()
        let targetID = store.flatMap { serviceID(for: service) ?? primaryState($0).serviceID }
        
        if let store, let targetID {
            let key = "State:/Network/Service/\(targetID)/DNS" as CFString
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
    
    // MARK: - Resolver State
    
    private func primaryState(_ store: SCDynamicStore?) -> (serviceID: String?, interface: String?) {
        guard let store,
              let value = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString),
              let dict = value as? [String: Any] else { return (nil, nil) }
        return (dict["PrimaryService"] as? String, dict["PrimaryInterface"] as? String)
    }
    
    private func resolvedDNSServers(_ store: SCDynamicStore?) -> [String] {
        if let servers = serverAddresses(store, at: "State:/Network/Global/DNS"), !servers.isEmpty {
            return servers
        }
        
        if let serviceID = primaryState(store).serviceID,
           let servers = serverAddresses(store, at: "State:/Network/Service/\(serviceID)/DNS"),
           !servers.isEmpty {
            return servers
        }
        
        return []
    }
    
    private func serverAddresses(_ store: SCDynamicStore?, at key: String) -> [String]? {
        guard let store,
              let value = SCDynamicStoreCopyValue(store, key as CFString),
              let dict = value as? [String: Any] else { return nil }
        return dict["ServerAddresses"] as? [String]
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
