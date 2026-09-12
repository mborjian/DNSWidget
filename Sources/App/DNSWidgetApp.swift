import SwiftUI

@main
struct DNSWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var storage = StorageService.shared
    @StateObject private var network = NetworkService.shared
    @StateObject private var latency = LatencyService.shared
    @StateObject private var wifiMonitor = WiFiMonitor.shared
    @StateObject private var launchAtLogin = LaunchAtLoginService.shared
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(storage)
                .environmentObject(network)
                .environmentObject(latency)
                .environmentObject(wifiMonitor)
                .environmentObject(launchAtLogin)
                .preferredColorScheme(.dark)
        } label: {
            Label {
                Text("DNS Widget")
            } icon: {
                Image(systemName: "network")
            }
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        NSApp.setActivationPolicy(.accessory)
        
        NetworkService.shared.restoreLastApplied()
        WiFiMonitor.shared.startMonitoring()
        WidgetCommandBridge.shared.start()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        WiFiMonitor.shared.stopMonitoring()
    }
}
