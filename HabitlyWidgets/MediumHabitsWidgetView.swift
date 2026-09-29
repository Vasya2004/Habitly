import SwiftUI
import WidgetKit

struct MediumHabitsWidgetView: View {
    let data: HabitlyWidgetData

    private var fraction: Double {
        data.total > 0 ? Double(data.completed) / Double(data.total) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Сегодня")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                    if data.bestStreak > 0 {
                        Text("🔥\(data.bestStreak)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary.opacity(0.7))
                    }
                    Spacer()
                    Text("\(data.completed)/\(data.total)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary.opacity(0.7))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.1))
                        Capsule().fill(Theme.brandGradient)
                            .frame(width: max(fraction > 0 ? 6 : 0, geo.size.width * fraction))
                    }
                }
                .frame(height: 5)
            }

            VStack(spacing: 8) {
                ForEach(Array(data.habits.prefix(4))) { habit in
                    HabitRow(habit: habit)
                }
                if data.habits.isEmpty {
                    Text("Нет привычек на сегодня")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.primary.opacity(0.6))
                }
            }
        }
    }
}

private struct HabitRow: View {
    let habit: HabitSnapshot

    var body: some View {
        HStack(spacing: 8) {
            HabitIconView(icon: habit.icon, size: 20)
                .frame(width: 24, height: 24)
                .background(Circle().fill(habit.accentColor.gradient))

            Text(habit.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.primary.opacity(habit.isCompleted ? 0.5 : 1))
                .strikethrough(habit.isCompleted, color: Color.primary.opacity(0.4))
                .lineLimit(1)

            Spacer()

            Button(intent: ToggleHabitIntent(habitID: habit.id.uuidString)) {
                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(habit.isCompleted ? AnyShapeStyle(habit.accentColor.gradient) : AnyShapeStyle(Color.primary.opacity(0.35)))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview(as: .systemMedium) {
    HabitlyWidget()
} timeline: {
    HabitlyEntry(date: .now, data: .placeholder)
}
