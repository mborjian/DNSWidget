import Foundation

struct SharedWidgetData: Codable, Sendable {
    let activeDNSName: String
    let primaryDNS: String
    let secondaryDNS: String
    let networkService: String
    let lastUpdated: Date
    let colorName: String
    
    static let empty = SharedWidgetData(
        activeDNSName: "No DNS",
        primaryDNS: "",
        secondaryDNS: "",
        networkService: "",
        lastUpdated: Date(),
        colorName: "blue"
    )
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: lastUpdated)
    }
    
    var hasSecondary: Bool {
        !secondaryDNS.isEmpty
    }
}

final class WidgetDataManager: @unchecked Sendable {
    static let shared = WidgetDataManager()
    
    private let suiteName = "group.com.dnswidget"
    private let key = "widget_data"
    
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    func save(_ data: SharedWidgetData) {
        guard let defaults = defaults,
              let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: key)
    }
    
    func load() -> SharedWidgetData {
        guard let defaults = defaults,
              let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(SharedWidgetData.self, from: data) else {
            return .empty
        }
        return decoded
    }
}