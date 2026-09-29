import Foundation
import SwiftData

/// Лёгкий снимок привычки для виджета — value type, безопасно пересекает границу процесса.
struct HabitSnapshot: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let icon: String
    let colorIndex: Int
    let type: HabitType
    let goalValue: Double
    let unit: String
    let value: Double
    let isCompleted: Bool
    let streak: Int

    var accentColor: HabitColor { HabitColor.palette[colorIndex % HabitColor.palette.count] }
}

struct WeekDaySnapshot: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let fraction: Double
    let isToday: Bool

    private enum CodingKeys: String, CodingKey { case date, fraction, isToday }
}

struct HabitlyWidgetData: Codable {
    let completed: Int
    let total: Int
    let bestStreak: Int
    let habits: [HabitSnapshot]
    let week: [WeekDaySnapshot]

    static let placeholder = HabitlyWidgetData(
        completed: 2, total: 5, bestStreak: 4,
        habits: [
            HabitSnapshot(id: UUID(), name: "Пить воду", icon: "💧", colorIndex: 1, type: .count, goalValue: 8, unit: "стаканов", value: 4, isCompleted: false, streak: 4),
            HabitSnapshot(id: UUID(), name: "Медитация", icon: "🧘", colorIndex: 8, type: .boolean, goalValue: 1, unit: "", value: 1, isCompleted: true, streak: 6),
            HabitSnapshot(id: UUID(), name: "Читать книгу", icon: "📖", colorIndex: 2, type: .timer, goalValue: 20, unit: "мин", value: 0, isCompleted: false, streak: 2)
        ],
        week: (0..<7).map { WeekDaySnapshot(date: .now, fraction: Double($0) / 7, isToday: $0 == 3) }
    )

    /// Источник данных для виджета: база в App Group, а если группа недоступна
    /// (бесплатный аккаунт разработчика) — снимок, который приложение кладёт в общий Keychain.
    static func load() -> HabitlyWidgetData {
        if SharedModelContainer.isAppGroupAvailable {
            return load(context: ModelContextProvider.shared.context)
        }
        return WidgetSnapshotKeychain.readSnapshot() ?? empty
    }

    static let empty = HabitlyWidgetData(completed: 0, total: 0, bestStreak: 0, habits: [], week: [])

    static func load(context: ModelContext) -> HabitlyWidgetData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let habits = (try? context.fetch(FetchDescriptor<Habit>()))?.filter { !$0.isArchived && !$0.isPaused } ?? []
        let scheduledToday = habits.filter { $0.isRequired(on: today, calendar: calendar) }
            .sorted { $0.sortOrder < $1.sortOrder }

        let snapshots: [HabitSnapshot] = scheduledToday.map { habit in
            let log = habit.log(on: today, calendar: calendar)
            return HabitSnapshot(
                id: habit.id, name: habit.name, icon: habit.icon, colorIndex: habit.colorIndex,
                type: habit.type, goalValue: habit.goalValue, unit: habit.unit,
                value: log?.value ?? 0, isCompleted: habit.isCompleted(on: today, calendar: calendar),
                streak: habit.streakStatsWithFreezes(asOf: today, calendar: calendar).currentStreak
            )
        }

        let completed = snapshots.filter(\.isCompleted).count
        let bestStreak = snapshots.map(\.streak).max() ?? 0

        var week: [WeekDaySnapshot] = []
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        if let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) {
            for offset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: offset, to: monday) else { continue }
                guard day <= today else {
                    week.append(WeekDaySnapshot(date: day, fraction: 0, isToday: false))
                    continue
                }
                let dayHabits = habits.filter { $0.schedule.isActive(on: day, calendar: calendar) && day >= calendar.startOfDay(for: $0.createdAt) }
                let dayCompleted = dayHabits.filter { $0.isCompleted(on: day, calendar: calendar) }.count
                let fraction = dayHabits.isEmpty ? 0 : Double(dayCompleted) / Double(dayHabits.count)
                week.append(WeekDaySnapshot(date: day, fraction: fraction, isToday: calendar.isDate(day, inSameDayAs: today)))
            }
        }

        return HabitlyWidgetData(completed: completed, total: scheduledToday.count, bestStreak: bestStreak, habits: snapshots, week: week)
    }
}
