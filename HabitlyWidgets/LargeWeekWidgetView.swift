import SwiftUI
import WidgetKit

struct LargeWeekWidgetView: View {
    let data: HabitlyWidgetData

    private let weekdaySymbols = Calendar.current.mondayFirstVeryShortWeekdaySymbols

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Эта неделя")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill").font(.system(size: 12))
                    Text("\(data.bestStreak)")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.orange)
            }

            HStack(spacing: 8) {
                ForEach(Array(zip(data.week.indices, data.week)), id: \.0) { index, day in
                    VStack(spacing: 4) {
                        Text(weekdaySymbols[index])
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.primary.opacity(0.5))
                        ZStack {
                            Circle().stroke(Color.primary.opacity(0.15), lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: day.fraction)
                                .stroke(day.isToday ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color.primary.opacity(0.6)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 26, height: 26)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Divider().background(Color.primary.opacity(0.15))

            VStack(spacing: 6) {
                ForEach(Array(data.habits.prefix(5))) { habit in
                    HStack(spacing: 8) {
                        HabitIconView(icon: habit.icon, size: 18)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(habit.accentColor.gradient))
                        Text(habit.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)
                        Spacer()
                        Button(intent: ToggleHabitIntent(habitID: habit.id.uuidString)) {
                            Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18))
                                .foregroundStyle(habit.isCompleted ? AnyShapeStyle(habit.accentColor.gradient) : AnyShapeStyle(Color.primary.opacity(0.35)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(habit.name)
                        .accessibilityValue(habit.isCompleted ? Text("Выполнено") : Text("Не выполнено"))
                    }
                }
            }
        }
    }
}

#Preview(as: .systemLarge) {
    HabitlyWidget()
} timeline: {
    HabitlyEntry(date: .now, data: .placeholder)
}
