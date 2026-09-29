import SwiftUI
import WidgetKit

struct MediumHabitsWidgetView: View {
    let data: HabitlyWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Сегодня")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(data.completed)/\(data.total)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }

            VStack(spacing: 6) {
                ForEach(Array(data.habits.prefix(4))) { habit in
                    HabitRow(habit: habit)
                }
                if data.habits.isEmpty {
                    Text("Нет привычек на сегодня")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
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
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Button(intent: ToggleHabitIntent(habitID: habit.id.uuidString)) {
                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(habit.isCompleted ? AnyShapeStyle(habit.accentColor.gradient) : AnyShapeStyle(Color.white.opacity(0.35)))
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
