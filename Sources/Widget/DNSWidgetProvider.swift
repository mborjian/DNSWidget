import WidgetKit

struct DNSWidgetProvider: TimelineProvider {
    private let dataManager = WidgetDataManager.shared
    
    func placeholder(in context: Context) -> DNSWidgetEntry {
        DNSWidgetEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DNSWidgetEntry) -> Void) {
        completion(DNSWidgetEntry.placeholder)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DNSWidgetEntry>) -> Void) {
        let data = dataManager.load()
        let entry = DNSWidgetEntry(date: Date(), data: data)
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
