import XCTest
import SwiftData
@testable import Habitly

/// Замеры стоимости того, что выполняется при отрисовке экранов. Не проверяют точное время,
/// а фиксируют порядок величин, чтобы регрессии в скорости было видно.
final class PerformanceTests: XCTestCase {
    fileprivate func makeHabits(count: Int, days: Int) throws -> (ModelContext, [Habit]) {
        let container = try ModelContainer(for: SharedModelContainer.schema,
                                           configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        var habits: [Habit] = []
        for i in 0..<count {
            let habit = Habit(name: "H\(i)", colorIndex: i,
                              type: i % 3 == 0 ? .count : .boolean, goalValue: i % 3 == 0 ? 8 : 1,
                              timeOfDay: TimeOfDay.allCases[i % 4],
                              createdAt: Calendar.current.date(byAdding: .day, value: -days, to: .now)!,
                              sortOrder: i)
            context.insert(habit)
            for d in 0..<days where d % 4 != 3 {
                let day = Calendar.current.date(byAdding: .day, value: -d, to: .now)!
                let log = HabitLog(date: day, value: habit.type == .count ? 8 : 1, habit: habit)
                habit.logs.append(log)
                context.insert(log)
            }
            habits.append(habit)
        }
        try context.save()
        return (context, habits)
    }

    func test_statsSummary_cost() throws {
        let (_, habits) = try makeHabits(count: 11, days: 365)
        measure { for period in StatsPeriod.allCases { _ = StatsCalculator.summary(habits: habits, period: period) } }
    }

    func test_streakStats_cost() throws {
        let (_, habits) = try makeHabits(count: 11, days: 365)
        measure { for habit in habits { _ = habit.streakStatsWithFreezes() } }
    }
}

extension PerformanceTests {
    /// Эталонный (медленный) расчёт: тот же результат, что был до оптимизации.
    private func naiveOverall(habits: [Habit], period: StatsPeriod) -> (rate: Double, completions: Int) {
        let calendar = Calendar.current
        let (start, end) = period.range(asOf: .now, calendar: calendar)
        var scheduled = 0, completed = 0
        for habit in habits where !habit.isArchived {
            var cursor = max(start, calendar.startOfDay(for: habit.createdAt))
            while cursor <= end {
                if habit.schedule.isActive(on: cursor, calendar: calendar) {
                    scheduled += 1
                    if habit.isCompleted(on: cursor, calendar: calendar) { completed += 1 }
                }
                cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
            }
        }
        return (scheduled > 0 ? Double(completed) / Double(scheduled) : 0, completed)
    }

    func test_optimizedSummary_matchesNaiveCalculation() throws {
        let (_, habits) = try makeHabits(count: 5, days: 120)
        habits[1].schedule = HabitSchedule(type: .daysOfWeek, weekdays: [2, 4, 6], timesPerWeek: 3)
        habits[2].isArchived = true
        for period in StatsPeriod.allCases {
            let fast = StatsCalculator.summary(habits: habits, period: period)
            let slow = naiveOverall(habits: habits, period: period)
            XCTAssertEqual(fast.overallRate, slow.rate, accuracy: 1e-9, "\(period)")
            XCTAssertEqual(fast.totalCompletions, slow.completions, "\(period)")
        }
    }
}
