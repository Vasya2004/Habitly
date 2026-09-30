import SwiftUI
import WidgetKit

struct SmallProgressWidgetView: View {
    let data: HabitlyWidgetData

    private var fraction: Double {
        data.total > 0 ? Double(data.completed) / Double(data.total) : 0
    }

    private var isAllDone: Bool { data.total > 0 && data.completed >= data.total }

    private var caption: String {
        if data.total == 0 { return String(localized: "Нет привычек") }
        return isAllDone ? String(localized: "Всё выполнено!") : String(localized: "Сегодня")
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(Theme.brandGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if isAllDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(Theme.brandGradient)
                } else {
                    VStack(spacing: 0) {
                        Text("\(data.completed)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Text("из \(data.total)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.primary.opacity(0.55))
                    }
                }
            }
            .frame(width: 88, height: 88)

            HStack(spacing: 6) {
                Text(caption)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.85))
                if data.bestStreak > 0 {
                    Text("🔥\(data.bestStreak)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary.opacity(0.7))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 4)
        .widgetURL(URL(string: "habitly://today"))
    }
}

#Preview(as: .systemSmall) {
    HabitlyWidget()
} timeline: {
    HabitlyEntry(date: .now, data: .placeholder)
}
