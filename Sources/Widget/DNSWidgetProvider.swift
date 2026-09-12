import WidgetKit

struct DNSWidgetProvider: TimelineProvider {
    private let dataManager = WidgetDataManager.shared

    func placeholder(in context: Context) -> DNSWidgetEntry {
        DNSWidgetEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (DNSWidgetEntry) -> Void) {
        let data = context.isPreview ? DNSWidgetEntry.placeholder.data : dataManager.load()
        completion(DNSWidgetEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DNSWidgetEntry>) -> Void) {
        let data = dataManager.load()
        let entry = DNSWidgetEntry(date: Date(), data: data)

        let interval: TimeInterval = data.applyingServerID == nil ? 300 : 20
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(interval))))
    }
}
