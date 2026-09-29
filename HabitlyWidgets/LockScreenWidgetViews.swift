import SwiftUI
import WidgetKit

/// Виджеты для экрана блокировки — монохромные (система сама задаёт тинт), поэтому
/// используем .widgetAccentable() вместо фирменного градиента.
struct LockScreenCircularView: View {
    let data: HabitlyWidgetData

    private var fraction: Double {
        data.total > 0 ? Double(data.completed) / Double(data.total) : 0
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Circle()
                .stroke(.white.opacity(0.25), lineWidth: 4)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .widgetAccentable()
            Text("\(data.completed)/\(data.total)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
    }
}

struct LockScreenRectangularView: View {
    let data: HabitlyWidgetData

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .widgetAccentable()
                    Text("\(data.bestStreak) дней")
                        .font(.system(size: 13, weight: .semibold))
                }
                Text("\(data.completed) из \(data.total) сегодня")
                    .font(.system(size: 11))
                    .opacity(0.8)
            }
            Spacer()
        }
    }
}

#Preview(as: .accessoryCircular) {
    HabitlyWidget()
} timeline: {
    HabitlyEntry(date: .now, data: .placeholder)
}
