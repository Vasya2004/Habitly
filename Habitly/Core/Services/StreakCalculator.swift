import Foundation

/// Один день истории выполнения привычки — вход для `StreakCalculator`.
/// Не зависит от SwiftData, поэтому логику можно тестировать без ModelContainer.
struct HabitDayRecord: Equatable {
    let date: Date
    let value: Double
    let isSkipped: Bool

    init(date: Date, value: Double, isSkipped: Bool = false) {
        self.date = date
        self.value = value
        self.isSkipped = isSkipped
    }
}

struct StreakStats: Equatable {
    let currentStreak: Int
    let bestStreak: Int
    let totalCompletions: Int
    let completionRate: Double

    static let zero = StreakStats(currentStreak: 0, bestStreak: 0, totalCompletions: 0, completionRate: 0)
}

/// Считает стрики и статистику выполнения привычки с учётом расписания, пропусков,
/// заморозок стрика и часового пояса (все даты нормализуются через переданный `Calendar`).
enum StreakCalculator {
    static func stats(
        type: HabitType,
        goalValue: Double,
        schedule: HabitSchedule,
        createdAt: Date,
        logs: [HabitDayRecord],
        frozenDates: Set<Date> = [],
        asOf: Date = .now,
        calendar: Calendar = .current
    ) -> StreakStats {
        let today = calendar.startOfDay(for: asOf)
        let start = calendar.startOfDay(for: createdAt)
        guard start <= today else { return .zero }

        let frozen = Set(frozenDates.map { calendar.startOfDay(for: $0) })

        var logsByDate: [Date: HabitDayRecord] = [:]
        for record in logs {
            logsByDate[calendar.startOfDay(for: record.date)] = record
        }

        func isCompleted(_ date: Date) -> Bool {
            guard let record = logsByDate[date], !record.isSkipped else { return false }
            switch type {
            case .boolean: return record.value >= 1
            case .count, .timer: return record.value >= goalValue
            }
        }

        func isScheduled(_ date: Date) -> Bool {
            schedule.isActive(on: date, calendar: calendar)
        }

        // Общая статистика выполнения считается по календарным дням расписания,
        // одинаково для всех типов расписания.
        var scheduledCount = 0
        var completedScheduledCount = 0
        var totalCompletions = 0
        var cursor = start
        while cursor <= today {
            if isCompleted(cursor) { totalCompletions += 1 }
            if isScheduled(cursor) {
                scheduledCount += 1
                if isCompleted(cursor) || frozen.contains(cursor) {
                    completedScheduledCount += 1
                }
            }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? today.addingTimeInterval(86_400)
            if cursor > today { break }
        }
        let completionRate = scheduledCount > 0 ? Double(completedScheduledCount) / Double(scheduledCount) : 0

        let (current, best): (Int, Int)
        switch schedule.type {
        case .everyDay, .daysOfWeek:
            current = currentDailyStreak(isCompleted: isCompleted, isScheduled: isScheduled, frozen: frozen, start: start, today: today, calendar: calendar)
            best = bestDailyStreak(isCompleted: isCompleted, isScheduled: isScheduled, frozen: frozen, start: start, today: today, calendar: calendar)
        case .timesPerWeek:
            current = currentWeeklyStreak(isCompleted: isCompleted, frozen: frozen, target: schedule.timesPerWeek, start: start, today: today, calendar: calendar)
            best = bestWeeklyStreak(isCompleted: isCompleted, frozen: frozen, target: schedule.timesPerWeek, start: start, today: today, calendar: calendar)
        }

        return StreakStats(
            currentStreak: current,
            bestStreak: best,
            totalCompletions: totalCompletions,
            completionRate: completionRate
        )
    }

    // MARK: - Daily / days-of-week streak

    private static func currentDailyStreak(
        isCompleted: (Date) -> Bool,
        isScheduled: (Date) -> Bool,
        frozen: Set<Date>,
        start: Date,
        today: Date,
        calendar: Calendar
    ) -> Int {
        var streak = 0
        var cursor = today
        while cursor >= start {
            if isScheduled(cursor) {
                if isCompleted(cursor) || frozen.contains(cursor) {
                    streak += 1
                } else if cursor != today {
                    // Пропущенный запланированный день (не сегодня) обрывает стрик.
                    break
                }
                // Если cursor == today и день ещё не выполнен — день ещё не закончился,
                // стрик не обрывается, но и не увеличивается.
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    private static func bestDailyStreak(
        isCompleted: (Date) -> Bool,
        isScheduled: (Date) -> Bool,
        frozen: Set<Date>,
        start: Date,
        today: Date,
        calendar: Calendar
    ) -> Int {
        var best = 0
        var run = 0
        var cursor = start
        while cursor <= today {
            if isScheduled(cursor) {
                if isCompleted(cursor) || frozen.contains(cursor) {
                    run += 1
                    best = max(best, run)
                } else if cursor != today {
                    run = 0
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return best
    }

    // MARK: - Times-per-week streak

    private static func weekCompletedCount(
        weekStart: Date,
        isCompleted: (Date) -> Bool,
        frozen: Set<Date>,
        rangeStart: Date,
        rangeEndInclusive: Date,
        calendar: Calendar
    ) -> Int {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else { return 0 }
        let clampedStart = max(interval.start, rangeStart)
        let clampedEndExclusive = min(interval.end, calendar.date(byAdding: .day, value: 1, to: rangeEndInclusive) ?? interval.end)
        guard clampedStart < clampedEndExclusive else { return 0 }

        var count = 0
        var day = clampedStart
        while day < clampedEndExclusive {
            if isCompleted(day) || frozen.contains(day) { count += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return count
    }

    private static func currentWeeklyStreak(
        isCompleted: (Date) -> Bool,
        frozen: Set<Date>,
        target: Int,
        start: Date,
        today: Date,
        calendar: Calendar
    ) -> Int {
        guard target > 0,
              var cursorWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start,
              let firstWeekStart = calendar.dateInterval(of: .weekOfYear, for: start)?.start
        else { return 0 }

        var streak = 0
        var isCurrentWeek = true
        while cursorWeekStart >= firstWeekStart {
            let completed = weekCompletedCount(weekStart: cursorWeekStart, isCompleted: isCompleted, frozen: frozen, rangeStart: start, rangeEndInclusive: today, calendar: calendar)
            if completed >= target {
                streak += 1
            } else if !isCurrentWeek {
                break
            }
            isCurrentWeek = false
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursorWeekStart) else { break }
            cursorWeekStart = previous
        }
        return streak
    }

    private static func bestWeeklyStreak(
        isCompleted: (Date) -> Bool,
        frozen: Set<Date>,
        target: Int,
        start: Date,
        today: Date,
        calendar: Calendar
    ) -> Int {
        guard target > 0,
              var cursorWeekStart = calendar.dateInterval(of: .weekOfYear, for: start)?.start,
              let lastWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start
        else { return 0 }

        var best = 0
        var run = 0
        var isLastWeek = false
        while cursorWeekStart <= lastWeekStart {
            isLastWeek = cursorWeekStart == lastWeekStart
            let completed = weekCompletedCount(weekStart: cursorWeekStart, isCompleted: isCompleted, frozen: frozen, rangeStart: start, rangeEndInclusive: today, calendar: calendar)
            if completed >= target {
                run += 1
                best = max(best, run)
            } else if !isLastWeek {
                run = 0
            }
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: cursorWeekStart) else { break }
            cursorWeekStart = next
        }
        return best
    }
}
