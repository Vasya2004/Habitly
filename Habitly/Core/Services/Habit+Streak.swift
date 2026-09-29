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

    func log(on date: Date, calendar: Calendar = .current) -> HabitLog? {
        logs.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func isLogCompleted(_ log: HabitLog) -> Bool {
        guard !log.isSkipped else { return false }
        switch type {
        case .boolean: return log.value >= 1
        case .count, .timer: return log.value >= goalValue
        }
    }

    /// Стрик с учётом дней, защищённых заморозкой (HabitLog.isFrozen).
    func streakStatsWithFreezes(asOf: Date = .now, calendar: Calendar = .current) -> StreakStats {
        let frozen = Set(logs.filter(\.isFrozen).map { calendar.startOfDay(for: $0.date) })
        return streakStats(asOf: asOf, calendar: calendar, frozenDates: frozen)
    }

    func isCompleted(on date: Date, calendar: Calendar = .current) -> Bool {
        guard let entry = log(on: date, calendar: calendar), !entry.isSkipped else { return false }
        switch type {
        case .boolean: return entry.value >= 1
        case .count, .timer: return entry.value >= goalValue
        }
    }

    /// Доля выполнения дня в диапазоне 0...1 — используется для интенсивности в хитмапе.
    func completionFraction(on date: Date, calendar: Calendar = .current) -> Double {
        guard let entry = log(on: date, calendar: calendar), !entry.isSkipped else { return 0 }
        switch type {
        case .boolean: return entry.value >= 1 ? 1 : 0
        case .count, .timer: return goalValue > 0 ? min(entry.value / goalValue, 1) : 0
        }
    }

    /// Процент выполнения запланированных дней в диапазоне [from, to] включительно.
    func completionRate(from: Date, to: Date, calendar: Calendar = .current) -> Double {
        let start = max(calendar.startOfDay(for: from), calendar.startOfDay(for: createdAt))
        let end = calendar.startOfDay(for: to)
        guard start <= end else { return 0 }

        var scheduled = 0
        var completed = 0
        var cursor = start
        while cursor <= end {
            if schedule.isActive(on: cursor, calendar: calendar) {
                scheduled += 1
                if isCompleted(on: cursor, calendar: calendar) { completed += 1 }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return scheduled > 0 ? Double(completed) / Double(scheduled) : 0
    }

    // MARK: - Недельная цель («X раз в неделю»)

    /// Сколько дней текущей недели привычка выполнена и какая цель — только для расписания `.timesPerWeek`.
    func weeklyProgress(asOf date: Date = .now, calendar: Calendar = .current) -> WeeklyProgress? {
        guard schedule.type == .timesPerWeek,
              let week = calendar.dateInterval(of: .weekOfYear, for: date) else { return nil }
        let done = logs.filter { week.contains($0.date) && !$0.isSkipped && isLogCompleted($0) }.count
        return WeeklyProgress(done: done, target: max(schedule.timesPerWeek, 1))
    }

    /// Нужно ли выполнять привычку в этот день, чтобы закрыть дневной прогресс: привычка
    /// с недельной целью, уже выполненной в другие дни, перестаёт «висеть» невыполненной.
    func isRequired(on date: Date, calendar: Calendar = .current) -> Bool {
        guard schedule.isActive(on: date, calendar: calendar) else { return false }
        guard let progress = weeklyProgress(asOf: date, calendar: calendar) else { return true }
        return !progress.isReached || isCompleted(on: date, calendar: calendar)
    }
}

struct WeeklyProgress: Equatable {
    let done: Int
    let target: Int

    var isReached: Bool { done >= target }
    var fraction: Double { min(Double(done) / Double(target), 1) }
}
