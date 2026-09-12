import AppIntents
import WidgetKit

struct ApplyDNSServerIntent: AppIntent {
    static var title: LocalizedStringResource { "Switch DNS Server" }

    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Server")
    var serverID: String

    init() {}

    init(serverID: String) {
        self.serverID = serverID
    }

    func perform() async throws -> some IntentResult {
        let manager = WidgetDataManager.shared
        manager.markApplying(serverID: serverID)
        manager.write(WidgetCommand(action: .apply, serverID: serverID, createdAt: Date()))
        manager.reloadWidgets()
        manager.notifyApp()
        return .result()
    }
}

struct ResetDNSIntent: AppIntent {
    static var title: LocalizedStringResource { "Use Automatic DNS" }

    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        let manager = WidgetDataManager.shared
        manager.markApplying(serverID: WidgetDataManager.resetMarker)
        manager.write(WidgetCommand(action: .reset, serverID: nil, createdAt: Date()))
        manager.reloadWidgets()
        manager.notifyApp()
        return .result()
    }
}
