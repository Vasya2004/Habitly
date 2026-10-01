import Foundation
import SwiftData

enum StatsPeriod: String, CaseIterable, Identifiable {
    case week, month, year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return String(localized: "Неделя")
        case .month: return String(localized: "Месяц")
        case .year: return String(localized: "Год")
        }
    }

    func range(asOf: Date, calendar: Calendar) -> (start: Date, end: Date) {
        let end = calendar.startOfDay(for: asOf)
        let start: Date
        switch self {
        case .week: start = calendar.date(byAdding: .day, value: -6, to: end) ?? end
        case .month: start = calendar.date(byAdding: .day, value: -29, to: end) ?? end
        case .year: start = calendar.date(byAdding: .day, value: -364, to: end) ?? end
        }
        return (start, end)
    }
}

struct HabitRateEntry: Identifiable {
    let habit: Habit
    let rate: Double
    var id: PersistentIdentifier { habit.persistentModelID }
}

struct ChartPoint: Identifiable {
    let date: Date
    let rate: Double
    var id: Date { date }
}

struct StatsSummary {
    let overallRate: Double
    let totalCompletions: Int
    let bestHabits: [HabitRateEntry]
    let bestWeekday: Int?
    let bestWeekdayCount: Int
    let bestTimeOfDay: TimeOfDay?
    let bestTimeOfDayCount: Int
    let chartPoints: [ChartPoint]
    let isMonthlyBucketed: Bool

    static let empty = StatsSummary(
        overallRate: 0, totalCompletions: 0, bestHabits: [],
        bestWeekday: nil, bestWeekdayCount: 0, bestTimeOfDay: nil, bestTimeOfDayCount: 0,
        chartPoints: [], isMonthlyBucketed: false
    )
}

enum StatsCalculator {
    /// Название дня недели по числу Calendar.weekday (1 = воскресенье).
    static func weekdayName(_ weekday: Int) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        let symbols = calendar.standaloneWeekdaySymbols
        guard (1...7).contains(weekday) else { return "" }
        return symbols[weekday - 1].capitalized
    }

    /// Предрасчитанные данные привычки для быстрых обходов по дням: расписание декодируется один раз,
    /// выполненные дни лежат во множестве — вместо JSON-декодирования и линейного поиска на каждый день.
    private struct HabitIndex {
        let habit: Habit
        let schedule: HabitSchedule
        let createdDay: Date
        let timeOfDay: TimeOfDay
        let completedDays: Set<Date>

        init(_ habit: Habit, calendar: Calendar) {
            self.habit = habit
            schedule = habit.schedule
            createdDay = calendar.startOfDay(for: habit.createdAt)
            timeOfDay = habit.timeOfDay
            var done = Set<Date>()
            for log in habit.logs where habit.isLogCompleted(log) {
                done.insert(calendar.startOfDay(for: log.date))
            }
            completedDays = done
        }

        func isScheduled(on day: Date, calendar: Calendar) -> Bool {
            day >= createdDay && schedule.isActive(on: day, calendar: calendar)
        }
    }

    static func summary(habits: [Habit], period: StatsPeriod, asOf: Date = .now, calendar: Calendar = .current) -> StatsSummary {
        let active = habits.filter { !$0.isArchived }
        guard !active.isEmpty else { return .empty }
        let (start, end) = period.range(asOf: asOf, calendar: calendar)
        let indexes = active.map { HabitIndex($0, calendar: calendar) }

        var totalScheduled = 0
        var totalCompleted = 0
        var weekdayCounts = [Int: Int]()
        var timeOfDayCounts = [TimeOfDay: Int]()
        var totalCompletions = 0

        var bestHabits: [HabitRateEntry] = []

        for index in indexes {
            var scheduled = 0
            var completed = 0
            var cursor = max(start, index.createdDay)
            while cursor <= end {
                if index.schedule.isActive(on: cursor, calendar: calendar) {
                    scheduled += 1
                    if index.completedDays.contains(cursor) {
                        completed += 1
                        totalCompletions += 1
                        weekdayCounts[calendar.component(.weekday, from: cursor), default: 0] += 1
                        timeOfDayCounts[index.timeOfDay, default: 0] += 1
                    }
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = next
            }
            totalScheduled += scheduled
            totalCompleted += completed
            if scheduled > 0 {
                bestHabits.append(HabitRateEntry(habit: index.habit, rate: Double(completed) / Double(scheduled)))
            }
        }

        bestHabits.sort { $0.rate > $1.rate }

        let bestWeekdayEntry = weekdayCounts.max { $0.value < $1.value }
        let bestTimeEntry = timeOfDayCounts.max { $0.value < $1.value }

        let useMonthlyBuckets = period == .year
        let chartPoints = useMonthlyBuckets
            ? monthlyChartPoints(indexes: indexes, start: start, end: end, calendar: calendar)
            : dailyChartPoints(indexes: indexes, start: start, end: end, calendar: calendar)

        return StatsSummary(
            overallRate: totalScheduled > 0 ? Double(totalCompleted) / Double(totalScheduled) : 0,
            totalCompletions: totalCompletions,
            bestHabits: Array(bestHabits.prefix(3)),
            bestWeekday: bestWeekdayEntry?.key,
            bestWeekdayCount: bestWeekdayEntry?.value ?? 0,
            bestTimeOfDay: bestTimeEntry?.key,
            bestTimeOfDayCount: bestTimeEntry?.value ?? 0,
            chartPoints: chartPoints,
            isMonthlyBucketed: useMonthlyBuckets
        )
    }

    private static func dayRate(indexes: [HabitIndex], on day: Date, calendar: Calendar) -> Double? {
        var scheduled = 0
        var completed = 0
        for index in indexes where index.isScheduled(on: day, calendar: calendar) {
            scheduled += 1
            if index.completedDays.contains(day) { completed += 1 }
        }
        guard scheduled > 0 else { return nil }
        return Double(completed) / Double(scheduled)
    }

    private static func dailyChartPoints(indexes: [HabitIndex], start: Date, end: Date, calendar: Calendar) -> [ChartPoint] {
        var points: [ChartPoint] = []
        var cursor = start
        while cursor <= end {
            points.append(ChartPoint(date: cursor, rate: dayRate(indexes: indexes, on: cursor, calendar: calendar) ?? 0))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return points
    }

    private static func monthlyChartPoints(indexes: [HabitIndex], start: Date, end: Date, calendar: Calendar) -> [ChartPoint] {
        var points: [ChartPoint] = []
        guard var cursor = calendar.dateInterval(of: .month, for: start)?.start else { return [] }
        while cursor <= end {
            guard let monthInterval = calendar.dateInterval(of: .month, for: cursor) else { break }
            var scheduled = 0
            var completed = 0
            var day = max(monthInterval.start, start)
            let monthEnd = min(monthInterval.end, calendar.date(byAdding: .day, value: 1, to: end) ?? monthInterval.end)
            while day < monthEnd {
                for index in indexes where index.isScheduled(on: day, calendar: calendar) {
                    scheduled += 1
                    if index.completedDays.contains(day) { completed += 1 }
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
            points.append(ChartPoint(date: monthInterval.start, rate: scheduled > 0 ? Double(completed) / Double(scheduled) : 0))
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = nextMonth
        }
        return points
    }
}
