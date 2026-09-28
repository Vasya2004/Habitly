import Foundation

extension Habit {
    /// Считает статистику стрика для этой привычки на основе её логов.
    func streakStats(asOf: Date = .now, calendar: Calendar = .current, frozenDates: Set<Date> = []) -> StreakStats {
        let records = logs.map { HabitDayRecord(date: $0.date, value: $0.value, isSkipped: $0.isSkipped) }
        return StreakCalculator.stats(
            type: type,
            goalValue: goalValue,
            schedule: schedule,
            createdAt: createdAt,
            logs: records,
            frozenDates: frozenDates,
            asOf: asOf,
            calendar: calendar
        )
    }
}
