import XCTest
@testable import Habitly

final class DayRolloverTests: XCTestCase {
    private func calendar(_ id: String = "UTC") -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: id)!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int = 0, in cal: Calendar) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    func test_sameDay_isNotAChange() {
        let cal = calendar()
        XCTAssertFalse(DayRollover.hasDayChanged(since: date(2026, 10, 1, 0, 0, in: cal), now: date(2026, 10, 1, 23, 59, in: cal), calendar: cal))
    }

    func test_acrossMidnight_isAChange() {
        let cal = calendar()
        XCTAssertTrue(DayRollover.hasDayChanged(since: date(2026, 10, 1, 23, 59, in: cal), now: date(2026, 10, 2, 0, 1, in: cal), calendar: cal))
    }

    func test_nextMorning_isAChange() {
        let cal = calendar()
        XCTAssertTrue(DayRollover.hasDayChanged(since: date(2026, 10, 1, 22, 30, in: cal), now: date(2026, 10, 2, 8, 15, in: cal), calendar: cal))
    }

    func test_monthAndYearBoundaries() {
        let cal = calendar()
        XCTAssertTrue(DayRollover.hasDayChanged(since: date(2026, 10, 31, 23, 0, in: cal), now: date(2026, 11, 1, 7, 0, in: cal), calendar: cal))
        XCTAssertTrue(DayRollover.hasDayChanged(since: date(2026, 12, 31, 23, 0, in: cal), now: date(2027, 1, 1, 7, 0, in: cal), calendar: cal))
    }

    func test_usesTheUsersTimeZone() {
        // 23:00 по UTC 1 октября — это уже 2 октября в Новосибирске (UTC+7).
        let utc = calendar("UTC"), nsk = calendar("Asia/Novosibirsk")
        let a = date(2026, 10, 1, 10, 0, in: utc), b = date(2026, 10, 1, 23, 0, in: utc)
        XCTAssertFalse(DayRollover.hasDayChanged(since: a, now: b, calendar: utc))
        XCTAssertTrue(DayRollover.hasDayChanged(since: a, now: b, calendar: nsk))
    }
}
