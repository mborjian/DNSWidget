import Foundation
import WidgetKit

struct SharedDNSServer: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let primaryDNS: String
    let secondaryDNS: String
    let colorName: String

    var hasSecondary: Bool { !secondaryDNS.isEmpty }

    var color: DNSColorName { DNSColorName(rawValue: colorName) ?? .gray }
}

enum DNSColorName: String, Sendable {
    case blue, green, orange, red, purple, teal, indigo, pink, gray
}

struct SharedWidgetData: Codable, Sendable {
    let activeDNSName: String
    let activeServerID: String?
    let primaryDNS: String
    let secondaryDNS: String
    let networkService: String
    let lastUpdated: Date
    let colorName: String
    let isAutomatic: Bool
    let servers: [SharedDNSServer]
    let applyingServerID: String?
    let applyingSince: Date?
    let lastError: String?

    static let empty = SharedWidgetData(
        activeDNSName: "Automatic",
        activeServerID: nil,
        primaryDNS: "",
        secondaryDNS: "",
        networkService: "",
        lastUpdated: Date(),
        colorName: "gray",
        isAutomatic: true,
        servers: [],
        applyingServerID: nil,
        applyingSince: nil,
        lastError: nil
    )

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: lastUpdated)
    }

    var hasSecondary: Bool { !secondaryDNS.isEmpty }

    var activeServer: SharedDNSServer? {
        guard let activeServerID else { return nil }
        return servers.first { $0.id == activeServerID }
    }

    func isApplying(_ id: String) -> Bool {
        guard applyingServerID == id else { return false }
        guard let applyingSince else { return true }
        return Date().timeIntervalSince(applyingSince) < 45
    }

    var isResetting: Bool { isApplying(WidgetDataManager.resetMarker) }
}

struct WidgetCommand: Codable, Sendable {
    enum Action: String, Codable, Sendable {
        case apply
        case reset
    }

    let action: Action
    let serverID: String?
    let createdAt: Date
}

final class WidgetDataManager: @unchecked Sendable {
    static let shared = WidgetDataManager()

    static let commandNotification = "com.dnswidget.widget.command"
    static let widgetBundleID = "com.dnswidget.widget"
    static let resetMarker = "__reset__"

    private let dataFileName = "widget-data.json"
    private let commandFileName = "widget-command.json"
    private let folderName = "DNSWidget"

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private var folder: URL? {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first

        let base: URL
        if let appSupport, appSupport.path.contains("/Library/Containers/") {
            base = appSupport
        } else {
            base = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Containers", isDirectory: true)
                .appendingPathComponent(Self.widgetBundleID, isDirectory: true)
                .appendingPathComponent("Data/Library/Application Support", isDirectory: true)
        }

        let folder = base.appendingPathComponent(folderName, isDirectory: true)
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDirectory) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return FileManager.default.fileExists(atPath: folder.path) ? folder : nil
    }

    private var dataURL: URL? { folder?.appendingPathComponent(dataFileName) }
    private var commandURL: URL? { folder?.appendingPathComponent(commandFileName) }

    @discardableResult
    func save(_ data: SharedWidgetData) -> Bool {
        guard let dataURL, let encoded = try? encoder.encode(data) else { return false }
        if let existing = try? Data(contentsOf: dataURL), existing == encoded { return false }
        try? encoded.write(to: dataURL, options: .atomic)
        return true
    }

    func load() -> SharedWidgetData {
        guard let dataURL,
              let raw = try? Data(contentsOf: dataURL),
              let decoded = try? decoder.decode(SharedWidgetData.self, from: raw)
        else { return .empty }
        return decoded
    }

    func markApplying(serverID: String) {
        guard let current = dataURL, FileManager.default.fileExists(atPath: current.path) else { return }
        let previous = load()
        save(SharedWidgetData(
            activeDNSName: previous.activeDNSName,
            activeServerID: previous.activeServerID,
            primaryDNS: previous.primaryDNS,
            secondaryDNS: previous.secondaryDNS,
            networkService: previous.networkService,
            lastUpdated: previous.lastUpdated,
            colorName: previous.colorName,
            isAutomatic: previous.isAutomatic,
            servers: previous.servers,
            applyingServerID: serverID,
            applyingSince: Date(),
            lastError: nil
        ))
    }

    func write(_ command: WidgetCommand) {
        guard let commandURL, let encoded = try? encoder.encode(command) else { return }
        try? encoded.write(to: commandURL, options: .atomic)
    }

    func pendingCommand() -> WidgetCommand? {
        guard let commandURL,
              let raw = try? Data(contentsOf: commandURL),
              let decoded = try? decoder.decode(WidgetCommand.self, from: raw)
        else { return nil }
        return decoded
    }

    func clearPendingCommand() {
        guard let commandURL else { return }
        try? FileManager.default.removeItem(at: commandURL)
    }

    func notifyApp() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(Self.commandNotification as CFString),
            nil,
            nil,
            true
        )
    }

    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
