import Foundation
import SwiftData

/// Наполняет базу демонстрационными привычками для ручной проверки экрана "Сегодня"
/// на этапах разработки, где полноценного редактора ещё нет. Используется только из
/// отладочного действия в UI — ничего не сеет автоматически при обычном запуске.
enum SampleDataSeeder {
    static func seed(into context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()

        let water = Habit(
            name: "Пить воду", icon: "💧", colorIndex: 1, type: .count,
            goalValue: 8, unit: "стаканов", schedule: .everyDay, timeOfDay: .morning
        )
        let reading = Habit(
            name: "Читать книгу", icon: "📖", colorIndex: 2, type: .timer,
            goalValue: 20, unit: "мин", schedule: .everyDay, timeOfDay: .evening
        )
        let workout = Habit(
            name: "Тренировка", icon: "🏋️", colorIndex: 5, type: .boolean,
            goalValue: 1, schedule: HabitSchedule(type: .daysOfWeek, weekdays: [2, 4, 6], timesPerWeek: 3),
            timeOfDay: .afternoon
        )
        let meditation = Habit(
            name: "Медитация", icon: "🧘", colorIndex: 8, type: .boolean,
            goalValue: 1, schedule: .everyDay, timeOfDay: .morning
        )
        let journaling = Habit(
            name: "Вести дневник", icon: "✍️", colorIndex: 3, type: .boolean,
            goalValue: 1, schedule: HabitSchedule(type: .timesPerWeek, weekdays: [], timesPerWeek: 4),
            timeOfDay: .evening
        )

        for (index, habit) in [water, reading, workout, meditation, journaling].enumerated() {
            habit.sortOrder = index
            habit.createdAt = calendar.date(byAdding: .day, value: -14, to: now) ?? now
            context.insert(habit)
        }

        // Небольшая история за последние дни, чтобы был виден стрик и прогресс.
        for offset in 1...4 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            context.insert(HabitLog(date: day, value: 8, habit: water))
            context.insert(HabitLog(date: day, value: 20, habit: reading))
            context.insert(HabitLog(date: day, value: 1, habit: meditation))
        }

        try? context.save()
    }
}
