import Foundation

final class StorageService: ObservableObject, @unchecked Sendable {
    static let shared = StorageService()
    
    @Published var servers: [DNSServer] = []
    
    private let userDefaultsKey = "dns_widget_servers"
    private let fileManager = FileManager.default
    
    private var storageURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("DNSWidget")
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("dns_servers.json")
    }
    
    init() {
        load()
        if servers.isEmpty {
            servers = DNSServer.presets
            save()
        }
    }
    
    func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([DNSServer].self, from: data) else {
            servers = DNSServer.presets
            return
        }
        servers = decoded
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(servers) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
    
    func add(_ server: DNSServer) {
        servers.append(server)
        save()
    }
    
    func update(_ server: DNSServer) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
            save()
        }
    }
    
    func delete(_ server: DNSServer) {
        guard !server.isPreset else { return }
        servers.removeAll { $0.id == server.id }
        save()
    }
    
    func togglePinned(_ server: DNSServer) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index].isPinned.toggle()
            save()
        }
    }
    
    func moveItem(_ dragged: DNSServer, relativeTo target: DNSServer, after: Bool) {
        guard dragged.id != target.id else { return }
        var dragged = dragged
        if dragged.isPinned != target.isPinned {
            dragged.isPinned = target.isPinned
            if let index = servers.firstIndex(where: { $0.id == dragged.id }) {
                servers[index] = dragged
            }
        }
        if target.isPinned {
            movePinned(dragged, relativeTo: target, after: after)
        } else {
            moveUnpinned(dragged, relativeTo: target, after: after)
        }
    }
    
    private func movePinned(_ dragged: DNSServer, relativeTo target: DNSServer, after: Bool) {
        var reordered = servers.filter { $0.isPinned }
        guard let from = reordered.firstIndex(where: { $0.id == dragged.id }),
              let to = reordered.firstIndex(where: { $0.id == target.id }),
              from != to else { return }
        reordered.remove(at: from)
        var insertAt = reordered.firstIndex(where: { $0.id == target.id }) ?? reordered.count
        if after { insertAt += 1 }
        reordered.insert(dragged, at: insertAt)
        applyGroupOrder(reordered, pinned: true)
    }
    
    private func moveUnpinned(_ dragged: DNSServer, relativeTo target: DNSServer, after: Bool) {
        var reordered = servers.filter { !$0.isPinned }
        guard let from = reordered.firstIndex(where: { $0.id == dragged.id }),
              let to = reordered.firstIndex(where: { $0.id == target.id }),
              from != to else { return }
        reordered.remove(at: from)
        var insertAt = reordered.firstIndex(where: { $0.id == target.id }) ?? reordered.count
        if after { insertAt += 1 }
        reordered.insert(dragged, at: insertAt)
        applyGroupOrder(reordered, pinned: false)
    }
    
    private func applyGroupOrder(_ reordered: [DNSServer], pinned: Bool) {
        var result: [DNSServer] = []
        var groupIndex = 0
        for server in servers {
            if server.isPinned == pinned {
                result.append(reordered[groupIndex])
                groupIndex += 1
            } else {
                result.append(server)
            }
        }
        servers = result
        save()
    }
    
    var pinnedServers: [DNSServer] {
        servers.filter { $0.isPinned }
    }
    
    func allServers() -> [DNSServer] {
        return servers
    }
}
