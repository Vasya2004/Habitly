import SwiftUI
import WidgetKit

struct SmallProgressWidgetView: View {
    let data: HabitlyWidgetData

    private var fraction: Double {
        data.total > 0 ? Double(data.completed) / Double(data.total) : 0
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.15), lineWidth: 9)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(Theme.brandGradient, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(data.completed)")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.primary)
                    Text("из \(data.total)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.primary.opacity(0.6))
                }
            }
            .frame(width: 84, height: 84)

            Text("Сегодня")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.8))
        }
        .widgetURL(URL(string: "habitly://today"))
    }
}

#Preview(as: .systemSmall) {
    HabitlyWidget()
} timeline: {
    HabitlyEntry(date: .now, data: .placeholder)
}
