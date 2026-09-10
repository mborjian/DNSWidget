import WidgetKit

struct DNSWidgetEntry: TimelineEntry {
    let date: Date
    let data: SharedWidgetData
    
    static let placeholder = DNSWidgetEntry(
        date: Date(),
        data: SharedWidgetData(
            activeDNSName: "Cloudflare",
            primaryDNS: "1.1.1.1",
            secondaryDNS: "1.0.0.1",
            networkService: "Wi-Fi",
            lastUpdated: Date(),
            colorName: "orange"
        )
    )
}
