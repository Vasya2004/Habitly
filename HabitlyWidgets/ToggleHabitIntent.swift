import AppIntents
import SwiftData
import WidgetKit

/// Отмечает привычку выполненной/невыполненной прямо из виджета, без открытия приложения.
struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Отметить привычку"
    static var description = IntentDescription("Отмечает привычку выполненной за сегодня")

    @Parameter(title: "ID привычки")
    var habitID: String

    init() {}

    init(habitID: String) {
        self.habitID = habitID
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: habitID) else { return .result() }
        let context = ModelContextProvider.shared.context
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.id == uuid })
        guard let habit = try? context.fetch(descriptor).first else { return .result() }

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
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
