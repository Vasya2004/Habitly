import Foundation
import SwiftData

/// Отметка привычки за сегодня — общая логика для App Intent виджета и для применения
/// отложенных нажатий с виджета внутри приложения.
enum HabitToggler {
    static func toggleToday(habitID: String, context: ModelContext) {
        guard let uuid = UUID(uuidString: habitID) else { return }
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.id == uuid })
        guard let habit = try? context.fetch(descriptor).first else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let existing = habit.log(on: today, calendar: calendar)
        let wasCompleted = existing.map { habit.isLogCompleted($0) } ?? false

        if let existing {
            existing.isSkipped = false
            existing.value = wasCompleted ? 0 : (habit.type == .boolean ? 1 : habit.goalValue)
        } else {
            let log = HabitLog(date: today, value: habit.type == .boolean ? 1 : habit.goalValue, habit: habit)
            habit.logs.append(log)
            context.insert(log)
        }
        try? context.save()
    }
}
