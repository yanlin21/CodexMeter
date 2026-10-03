import SwiftUI
import WidgetKit

struct CodexMeterEntry: TimelineEntry {
    let date: Date
    let snapshot: CodexUsageSnapshot?
}

struct CodexMeterProvider: TimelineProvider {
    func placeholder(in context: Context) -> CodexMeterEntry {
        CodexMeterEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CodexMeterEntry) -> Void) {
        completion(CodexMeterEntry(
            date: Date(),
            snapshot: context.isPreview ? .placeholder : (AppGroupStore.load() ?? .placeholder)
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CodexMeterEntry>) -> Void) {
        let entry = CodexMeterEntry(date: Date(), snapshot: AppGroupStore.load())
        let nextCheck = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
            ?? Date().addingTimeInterval(30 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextCheck)))
    }
}

struct CodexMeterWidget: Widget {
    let kind = "CodexMeterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CodexMeterProvider()) { entry in
            CodexMeterWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { Color(nsColor: .windowBackgroundColor) }
        }
        .configurationDisplayName("Codex Usage")
        .description("See your current Codex quota and reset time.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct CodexMeterWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CodexMeterEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(snapshot: entry.snapshot)
        default:
            MediumWidgetView(snapshot: entry.snapshot)
        }
    }
}

