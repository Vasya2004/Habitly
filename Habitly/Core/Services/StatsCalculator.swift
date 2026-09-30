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

    static func summary(habits: [Habit], period: StatsPeriod, asOf: Date = .now, calendar: Calendar = .current) -> StatsSummary {
        let active = habits.filter { !$0.isArchived }
        guard !active.isEmpty else { return .empty }
        let (start, end) = period.range(asOf: asOf, calendar: calendar)

        var totalScheduled = 0
        var totalCompleted = 0
        var weekdayCounts = [Int: Int]()
        var timeOfDayCounts = [TimeOfDay: Int]()
        var totalCompletions = 0

        var bestHabits: [HabitRateEntry] = []

        for habit in active {
            var scheduled = 0
            var completed = 0
            var cursor = max(start, calendar.startOfDay(for: habit.createdAt))
            while cursor <= end {
                if habit.schedule.isActive(on: cursor, calendar: calendar) {
                    scheduled += 1
                    if habit.isCompleted(on: cursor, calendar: calendar) {
                        completed += 1
                        totalCompletions += 1
                        let weekday = calendar.component(.weekday, from: cursor)
                        weekdayCounts[weekday, default: 0] += 1
                        timeOfDayCounts[habit.timeOfDay, default: 0] += 1
                    }
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = next
            }
            totalScheduled += scheduled
            totalCompleted += completed
            if scheduled > 0 {
                bestHabits.append(HabitRateEntry(habit: habit, rate: Double(completed) / Double(scheduled)))
            }
        }

        bestHabits.sort { $0.rate > $1.rate }

        let bestWeekdayEntry = weekdayCounts.max { $0.value < $1.value }
        let bestTimeEntry = timeOfDayCounts.max { $0.value < $1.value }

        let useMonthlyBuckets = period == .year
        let chartPoints = useMonthlyBuckets
            ? monthlyChartPoints(habits: active, start: start, end: end, calendar: calendar)
            : dailyChartPoints(habits: active, start: start, end: end, calendar: calendar)

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

    private static func dayRate(habits: [Habit], on day: Date, calendar: Calendar) -> Double? {
        var scheduled = 0
        var completed = 0
        for habit in habits {
            guard day >= calendar.startOfDay(for: habit.createdAt), habit.schedule.isActive(on: day, calendar: calendar) else { continue }
            scheduled += 1
            if habit.isCompleted(on: day, calendar: calendar) { completed += 1 }
        }
        guard scheduled > 0 else { return nil }
        return Double(completed) / Double(scheduled)
    }

    private static func dailyChartPoints(habits: [Habit], start: Date, end: Date, calendar: Calendar) -> [ChartPoint] {
        var points: [ChartPoint] = []
        var cursor = start
        while cursor <= end {
            points.append(ChartPoint(date: cursor, rate: dayRate(habits: habits, on: cursor, calendar: calendar) ?? 0))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return points
    }

    private static func monthlyChartPoints(habits: [Habit], start: Date, end: Date, calendar: Calendar) -> [ChartPoint] {
        var points: [ChartPoint] = []
        guard var cursor = calendar.dateInterval(of: .month, for: start)?.start else { return [] }
        while cursor <= end {
            guard let monthInterval = calendar.dateInterval(of: .month, for: cursor) else { break }
            var scheduled = 0
            var completed = 0
            var day = max(monthInterval.start, start)
            let monthEnd = min(monthInterval.end, calendar.date(byAdding: .day, value: 1, to: end) ?? monthInterval.end)
            while day < monthEnd {
                for habit in habits {
                    guard day >= calendar.startOfDay(for: habit.createdAt), habit.schedule.isActive(on: day, calendar: calendar) else { continue }
                    scheduled += 1
                    if habit.isCompleted(on: day, calendar: calendar) { completed += 1 }
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
