import Foundation
import ServiceManagement
import SwiftUI

@available(macOS 13.0, *)
final class LaunchAtLoginService: ObservableObject, @unchecked Sendable {
    static let shared = LaunchAtLoginService()
    
    @Published var isEnabled: Bool = false
    
    init() {
        refresh()
    }
    
    var status: SMAppService.Status {
        SMAppService.mainApp.status
    }
    
    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    func toggle() {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            refresh()
        } catch {
            print("[LaunchAtLogin] Failed to toggle: \(error)")
        }
    }
}
