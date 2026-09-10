import SwiftUI
import WidgetKit

@main
struct DNSWidgetBundle: WidgetBundle {
    var body: some Widget {
        DNSStatusWidget()
    }
}

struct DNSStatusWidget: Widget {
    let kind: String = "DNSStatusWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DNSWidgetProvider()) { entry in
            DNSWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.black
                }
        }
        .configurationDisplayName("DNS Status")
        .description("Shows your active DNS resolver and connection details.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    DNSStatusWidget()
} timeline: {
    DNSWidgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    DNSStatusWidget()
} timeline: {
    DNSWidgetEntry.placeholder
}

#Preview(as: .systemLarge) {
    DNSStatusWidget()
} timeline: {
    DNSWidgetEntry.placeholder
}
