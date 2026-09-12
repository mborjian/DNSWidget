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
        }
        .configurationDisplayName("DNS Status")
        .description("See which DNS you're using and switch it with a tap.")
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
