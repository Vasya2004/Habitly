import WidgetKit
import SwiftUI

struct HabitlyEntry: TimelineEntry {
    let date: Date
    let data: HabitlyWidgetData
}

struct HabitlyProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitlyEntry {
        HabitlyEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitlyEntry) -> Void) {
        completion(HabitlyEntry(date: .now, data: context.isPreview ? .placeholder : .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitlyEntry>) -> Void) {
        let entry = HabitlyEntry(date: .now, data: .load())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct HabitlyWidget: Widget {
    let kind = "HabitlyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitlyProvider()) { entry in
            HabitlyWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackground()
                }
        }
        .configurationDisplayName("Habitly")
        .description("Прогресс дня и быстрая отметка привычек.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular])
    }
}

/// Фон виджета следует системной теме (светлый/тёмный).
private struct WidgetBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Theme.backgroundGradient(for: scheme)
    }
}

struct HabitlyWidgetView: View {
    let entry: HabitlyEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallProgressWidgetView(data: entry.data)
        case .systemMedium:
            MediumHabitsWidgetView(data: entry.data)
        case .systemLarge:
            LargeWeekWidgetView(data: entry.data)
        case .accessoryCircular:
            LockScreenCircularView(data: entry.data)
        case .accessoryRectangular:
            LockScreenRectangularView(data: entry.data)
        default:
            SmallProgressWidgetView(data: entry.data)
        }
    }
}
