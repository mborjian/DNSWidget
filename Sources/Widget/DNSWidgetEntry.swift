import WidgetKit

struct DNSWidgetEntry: TimelineEntry {
    let date: Date
    let data: SharedWidgetData

    static let placeholder = DNSWidgetEntry(
        date: Date(),
        data: SharedWidgetData(
            activeDNSName: "Cloudflare",
            activeServerID: "cloudflare",
            primaryDNS: "1.1.1.1",
            secondaryDNS: "1.0.0.1",
            networkService: "Wi-Fi",
            lastUpdated: Date(),
            colorName: "orange",
            isAutomatic: false,
            servers: [
                SharedDNSServer(id: "cloudflare", name: "Cloudflare", primaryDNS: "1.1.1.1", secondaryDNS: "1.0.0.1", colorName: "orange"),
                SharedDNSServer(id: "google", name: "Google DNS", primaryDNS: "8.8.8.8", secondaryDNS: "8.8.4.4", colorName: "blue"),
                SharedDNSServer(id: "quad9", name: "Quad9", primaryDNS: "9.9.9.9", secondaryDNS: "149.112.112.112", colorName: "purple"),
                SharedDNSServer(id: "adguard", name: "AdGuard DNS", primaryDNS: "94.140.14.14", secondaryDNS: "94.140.15.15", colorName: "teal"),
                SharedDNSServer(id: "opendns", name: "OpenDNS", primaryDNS: "208.67.222.222", secondaryDNS: "208.67.220.220", colorName: "green"),
                SharedDNSServer(id: "nextdns", name: "NextDNS", primaryDNS: "45.90.28.0", secondaryDNS: "45.90.30.0", colorName: "indigo")
            ],
            applyingServerID: nil,
            applyingSince: nil,
            lastError: nil
        )
    )
}
