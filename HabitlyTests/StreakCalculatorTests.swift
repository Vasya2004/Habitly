import XCTest
@testable import Habitly

final class StreakCalculatorTests: XCTestCase {

    // MARK: - Helpers

    private func utcCalendar(firstWeekday: Int = 2) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12, calendar: Calendar) -> Date {
        var components = DateComponents()
        components.year = y; components.month = m; components.day = d; components.hour = hour
        return calendar.date(from: components)!
    }

    // MARK: - Ежедневное расписание

    func test_everyDay_basicConsecutiveStreak() {
        let cal = utcCalendar()
        let created = date(2026, 1, 1, calendar: cal)
        let today = date(2026, 1, 5, calendar: cal)
        let logs = (1...5).map { HabitDayRecord(date: date(2026, 1, $0, calendar: cal), value: 1) }

        let stats = StreakCalculator.stats(
            type: .boolean, goalValue: 1, schedule: .everyDay,
            createdAt: created, logs: logs, asOf: today, calendar: cal
        )

        XCTAssertEqual(stats.currentStreak, 5)
        XCTAssertEqual(stats.bestStreak, 5)
        XCTAssertEqual(stats.totalCompletions, 5)
    }

    func test_everyDay_missedDayBreaksCurrentStreakButKeepsBest() {
        let cal = utcCalendar()
        let created = date(2026, 1, 1, calendar: cal)
        let today = date(2026, 1, 10, calendar: cal)
        // Выполнено 1-4 (стрик 4), день 5 пропущен, выполнено 6-10 (стрик 5)
        var logs = (1...4).map { HabitDayRecord(date: date(2026, 1, $0, calendar: cal), value: 1) }
        logs += (6...10).map { HabitDayRecord(date: date(2026, 1, $0, calendar: cal), value: 1) }

        let stats = StreakCalculator.stats(
            type: .boolean, goalValue: 1, schedule: .everyDay,
            createdAt: created, logs: logs, asOf: today, calendar: cal
        )

        XCTAssertEqual(stats.currentStreak, 5)
        XCTAssertEqual(stats.bestStreak, 5)
        XCTAssertEqual(stats.totalCompletions, 9)
    }

    func test_everyDay_todayNotYetCompleted_doesNotBreakStreak() {
        let cal = utcCalendar()
        let created = date(2026, 1, 1, calendar: cal)
        let today = date(2026, 1, 5, calendar: cal)
        // Выполнено 1-4, сегодня (5) ещё не отмечено
        let logs = (1...4).map { HabitDayRecord(date: date(2026, 1, $0, calendar: cal), value: 1) }

        let stats = StreakCalculator.stats(
            type: .boolean, goalValue: 1, schedule: .everyDay,
            createdAt: created, logs: logs, asOf: today, calendar: cal
        )

        XCTAssertEqual(stats.currentStreak, 4, "Незавершённый сегодняшний день не должен обнулять стрик")
    }

    func test_everyDay_explicitSkip_breaksStreak() {
        let cal = utcCalendar()
        let created = date(2026, 1, 1, calendar: cal)
        let today = date(2026, 1, 5, calendar: cal)
        var logs = (1...3).map { HabitDayRecord(date: date(2026, 1, $0, calendar: cal), value: 1) }
        logs.append(HabitDayRecord(date: date(2026, 1, 4, calendar: cal), value: 0, isSkipped: true))
        logs.append(HabitDayRecord(date: date(2026, 1, 5, calendar: cal), value: 1))

        let stats = StreakCalculator.stats(
            type: .boolean, goalValue: 1, schedule: .everyDay,
            createdAt: created, logs: logs, asOf: today, calendar: cal
        )

        XCTAssertEqual(stats.currentStreak, 1, "Пропуск (skip) в прошлом должен обрывать стрик")
        XCTAssertEqual(stats.bestStreak, 3)
    }

    // MARK: - Дни недели

    func test_daysOfWeek_unscheduledDaysDoNotBreakStreak() {
        let cal = utcCalendar()
        // 2026-01-05 — понедельник. Расписание: пн(2), ср(4), пт(6).
        let schedule = HabitSchedule(type: .daysOfWeek, weekdays: [2, 4, 6], timesPerWeek: 3)
        let created = date(2026, 1, 5, calendar: cal)
        let today = date(2026, 1, 9, calendar: cal) // пятница
        let logs = [
            HabitDayRecord(date: date(2026, 1, 5, calendar: cal), value: 1), // пн
            HabitDayRecord(date: date(2026, 1, 7, calendar: cal), value: 1), // ср
            HabitDayRecord(date: date(2026, 1, 9, calendar: cal), value: 1)  // пт
        ]

        let stats = StreakCalculator.stats(
            type: .boolean, goalValue: 1, schedule: schedule,
            createdAt: created, logs: logs, asOf: today, calendar: cal
        )

        XCTAssertEqual(stats.currentStreak, 3, "Дни вне расписания (вт, чт) не должны учитываться и не должны рвать стрик")
        XCTAssertEqual(stats.completionRate, 1.0, accuracy: 0.0001)
    }

    func test_daysOfWeek_missedScheduledDayBreaksStreak() {
        let cal = utcCalendar()
        let schedule = HabitSchedule(type: .daysOfWeek, weekdays: [2, 4, 6], timesPerWeek: 3)
        let created = date(2026, 1, 5, calendar: cal)
        let today = date(2026, 1, 9, calendar: cal)
        // Среда (7 число) пропущена — не размечена вовсе.
        let logs = [
            HabitDayRecord(date: date(2026, 1, 5, calendar: cal), value: 1),
            HabitDayRecord(date: date(2026, 1, 9, calendar: cal), value: 1)
        ]

        let stats = StreakCalculator.stats(
            type: .boolean, goalValue: 1, schedule: schedule,
            createdAt: created, logs: logs, asOf: today, calendar: cal
        )

        XCTAssertEqual(stats.currentStreak, 1)
    }

    // MARK: - Заморозка стрика

    func test_streakFreeze_coversMissedScheduledDay() {
        let cal = utcCalendar()
        let created = date(2026, 1, 1, calendar: cal)
        let today = date(2026, 1, 5, calendar: cal)
        var logs = (1...2).map { HabitDayRecord(date: date(2026, 1, $0, calendar: cal), value: 1) }
        // День 3 пропущен, но защищён заморозкой.
        logs += (4...5).map { HabitDayRecord(date: date(2026, 1, $0, calendar: cal), value: 1) }
        let frozen: Set<Date> = [date(2026, 1, 3, calendar: cal)]

        let stats = StreakCalculator.stats(
            type: .boolean, goalValue: 1, schedule: .everyDay,
            createdAt: created, logs: logs, frozenDates: frozen, asOf: today, calendar: cal
        )

        XCTAssertEqual(stats.currentStreak, 5, "Замороженный день должен сохранять непрерывность стрика")
    }

    // MARK: - Количественные привычки

    func test_countType_requiresGoalValue() {
        let cal = utcCalendar()
        let created = date(2026, 1, 1, calendar: cal)
        let today = date(2026, 1, 2, calendar: cal)
        let logs = [
            HabitDayRecord(date: date(2026, 1, 1, calendar: cal), value: 8),
            HabitDayRecord(date: date(2026, 1, 2, calendar: cal), value: 3) // меньше цели
        ]

        let stats = StreakCalculator.stats(
            type: .count, goalValue: 8, schedule: .everyDay,
            createdAt: created, logs: logs, asOf: today, calendar: cal
        )

        XCTAssertEqual(stats.currentStreak, 1, "Вчерашний день выполнен полностью, а сегодняшний (незавершённый) не рвёт стрик")
        XCTAssertEqual(stats.totalCompletions, 1)
    }

    // MARK: - X раз в неделю

    func test_timesPerWeek_consecutiveSatisfiedWeeks() {
        let cal = utcCalendar() // неделя начинается с понедельника
        let schedule = HabitSchedule(type: .timesPerWeek, weekdays: [], timesPerWeek: 2)
        let created = date(2026, 1, 5, calendar: cal) // понедельник, неделя 1
        let today = date(2026, 1, 25, calendar: cal)  // воскресенье, неделя 3 закончилась

        // Неделя 1 (5-11 янв): 2 выполнения. Неделя 2 (12-18): 2. Неделя 3 (19-25): 2.
        let logs = [
            HabitDayRecord(date: date(2026, 1, 5, calendar: cal), value: 1),
            HabitDayRecord(date: date(2026, 1, 6, calendar: cal), value: 1),
            HabitDayRecord(date: date(2026, 1, 12, calendar: cal), value: 1),
            HabitDayRecord(date: date(2026, 1, 14, calendar: cal), value: 1),
            HabitDayRecord(date: date(2026, 1, 19, calendar: cal), value: 1),
            HabitDayRecord(date: date(2026, 1, 21, calendar: cal), value: 1)
        ]

        let stats = StreakCalculator.stats(
            type: .boolean, goalValue: 1, schedule: schedule,
            createdAt: created, logs: logs, asOf: today, calendar: cal
        )

        XCTAssertEqual(stats.currentStreak, 3, "Три подряд закрытые недели должны дать стрик 3")
        XCTAssertEqual(stats.bestStreak, 3)
    }

    func test_timesPerWeek_currentWeekInProgressDoesNotBreakStreak() {
        let cal = utcCalendar()
        let schedule = HabitSchedule(type: .timesPerWeek, weekdays: [], timesPerWeek: 3)
        let created = date(2026, 1, 5, calendar: cal)
        let today = date(2026, 1, 13, calendar: cal) // вторник второй недели, цель этой недели ещё не достигнута

        let logs = [
            HabitDayRecord(date: date(2026, 1, 5, calendar: cal), value: 1),
            HabitDayRecord(date: date(2026, 1, 6, calendar: cal), value: 1),
            HabitDayRecord(date: date(2026, 1, 7, calendar: cal), value: 1),
            HabitDayRecord(date: date(2026, 1, 12, calendar: cal), value: 1) // текущая неделя, только 1 из 3
        ]

        let stats = StreakCalculator.stats(
            type: .boolean, goalValue: 1, schedule: schedule,
            createdAt: created, logs: logs, asOf: today, calendar: cal
        )

        XCTAssertEqual(stats.currentStreak, 1, "Текущая незакрытая неделя не должна обрывать стрик прошлой недели")
    }

    func test_timesPerWeek_pastUnmetWeekBreaksStreak() {
        let cal = utcCalendar()
        let schedule = HabitSchedule(type: .timesPerWeek, weekdays: [], timesPerWeek: 3)
        let created = date(2026, 1, 5, calendar: cal)
        let today = date(2026, 1, 25, calendar: cal)

        let logs = [
            // Неделя 1: полностью выполнена (3 раза)
            HabitDayRecord(date: date(2026, 1, 5, calendar: cal), value: 1),
            HabitDayRecord(date: date(2026, 1, 6, calendar: cal), value: 1),
            HabitDayRecord(date: date(2026, 1, 7, calendar: cal), value: 1),
            // Неделя 2: только 1 раз — цель не достигнута
            HabitDayRecord(date: date(2026, 1, 12, calendar: cal), value: 1),
            // Неделя 3: снова выполнена полностью
            HabitDayRecord(date: date(2026, 1, 19, calendar: cal), value: 1),
            HabitDayRecord(date: date(2026, 1, 20, calendar: cal), value: 1),
            HabitDayRecord(date: date(2026, 1, 21, calendar: cal), value: 1)
        ]

        let stats = StreakCalculator.stats(
            type: .boolean, goalValue: 1, schedule: schedule,
            createdAt: created, logs: logs, asOf: today, calendar: cal
        )

        XCTAssertEqual(stats.currentStreak, 1, "Текущая неделя (3) закрыта, но неделя 2 закрыта не была — стрик обрывается на ней")
        XCTAssertEqual(stats.bestStreak, 1)
    }

    // MARK: - Часовой пояс

    func test_timezoneAffectsDayBucketing() {
        // Лог сделан в 23:30 UTC 9 марта — за 1.5 часа ДО момента создания привычки (01:00 UTC 10 марта).
        var utcComponents = DateComponents()
        utcComponents.year = 2026; utcComponents.month = 3; utcComponents.day = 9
        utcComponents.hour = 23; utcComponents.minute = 30
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        let logInstant = utcCal.date(from: utcComponents)!

        var createdComponents = DateComponents()
        createdComponents.year = 2026; createdComponents.month = 3; createdComponents.day = 10
        createdComponents.hour = 1; createdComponents.minute = 0
        let createdInstant = utcCal.date(from: createdComponents)!

        var asOfComponents = DateComponents()
        asOfComponents.year = 2026; asOfComponents.month = 3; asOfComponents.day = 12
        asOfComponents.hour = 12
        let asOfInstant = utcCal.date(from: asOfComponents)!

        let logs = [HabitDayRecord(date: logInstant, value: 1)]

        // В UTC лог (9 марта, 23:30) попадает в день ДО создания привычки (10 марта) и исключается.
        let statsUTC = StreakCalculator.stats(
            type: .boolean, goalValue: 1, schedule: .everyDay,
            createdAt: createdInstant, logs: logs, asOf: asOfInstant, calendar: utcCal
        )
        XCTAssertEqual(statsUTC.totalCompletions, 0, "Лог сделан раньше даты создания привычки в UTC — не должен учитываться")

        // В часовом поясе UTC-5 те же абсолютные моменты сдвигаются на 5 часов назад:
        // и лог (18:30 местного 9 марта), и момент создания (20:00 местного 9 марта) попадают
        // в один и тот же календарный день — лог больше не «раньше» дня создания.
        var westCal = Calendar(identifier: .gregorian)
        westCal.timeZone = TimeZone(secondsFromGMT: -5 * 3600)!
        let statsWest = StreakCalculator.stats(
            type: .boolean, goalValue: 1, schedule: .everyDay,
            createdAt: createdInstant, logs: logs, asOf: asOfInstant, calendar: westCal
        )
        XCTAssertEqual(statsWest.totalCompletions, 1, "В UTC-5 лог и дата создания попадают в один день — лог должен учитываться")
    }

    // MARK: - Процент выполнения

    func test_completionRate_overScheduledDays() {
        let cal = utcCalendar()
        let created = date(2026, 1, 1, calendar: cal)
        let today = date(2026, 1, 4, calendar: cal)
        let logs = [
            HabitDayRecord(date: date(2026, 1, 1, calendar: cal), value: 1),
            HabitDayRecord(date: date(2026, 1, 3, calendar: cal), value: 1)
        ]

        let stats = StreakCalculator.stats(
            type: .boolean, goalValue: 1, schedule: .everyDay,
            createdAt: created, logs: logs, asOf: today, calendar: cal
        )

        // 4 запланированных дня (1-4 янв), выполнено 2 → 50%.
        XCTAssertEqual(stats.completionRate, 0.5, accuracy: 0.0001)
    }
}
