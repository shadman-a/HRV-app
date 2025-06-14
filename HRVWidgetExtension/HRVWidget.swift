import WidgetKit
import SwiftUI

struct HRVEntry: TimelineEntry {
    let date: Date
    let hrv: Int
}

struct HRVProvider: TimelineProvider {
    func placeholder(in context: Context) -> HRVEntry {
        HRVEntry(date: .now, hrv: 65)
    }

    func getSnapshot(in context: Context, completion: @escaping (HRVEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HRVEntry>) -> Void) {
        let entry = HRVEntry(date: .now, hrv: loadHRV())
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadHRV() -> Int {
        if let data = UserDefaults.standard.data(forKey: "hrvHistory"),
           let records = try? JSONDecoder().decode([HRVRecord].self, from: data),
           let last = records.last {
            return last.value
        }
        return 0
    }
}

struct HRVWidgetEntryView : View {
    var entry: HRVProvider.Entry

    var body: some View {
        VStack {
            Text("HRV")
            Text("\(entry.hrv) ms")
        }
    }
}

@main
struct HRVWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HRVWidget", provider: HRVProvider()) { entry in
            HRVWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Current HRV")
        .description("Shows your most recent HRV value")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
