import WidgetKit
import SwiftUI

struct EarningsEntry: TimelineEntry {
    let date: Date
    let earnings: Double
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> EarningsEntry {
        EarningsEntry(date: Date(), earnings: 0.0)
    }

    func getSnapshot(in context: Context, completion: @escaping (EarningsEntry) -> ()) {
        completion(EarningsEntry(date: Date(), earnings: 0.0))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EarningsEntry>) -> ()) {
        // In production, load data from shared container or network
        let entry = EarningsEntry(date: Date(), earnings: 12.34)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 30)))
        completion(timeline)
    }
}

struct EarningsWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Today's Earnings")
                .font(.caption)
            Text(entry.earnings, format: .currency(code: "USD"))
                .font(.title2.bold())
        }
        .padding()
    }
}

struct EarningsWidget: Widget {
    let kind: String = "EarningsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            EarningsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AdMob Earnings")
        .description("Shows today's AdMob earnings.")
    }
}
