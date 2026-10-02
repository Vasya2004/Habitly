import Foundation

/// Смена календарного дня: сигнал для экранов, что «сегодня» теперь другой день.
struct DayChange: Equatable {
    /// Растёт при каждой смене дня — по нему экраны замечают событие.
    var token = 0
    /// true — приложение вернулось из фона в новый день: нужно вернуть пользователя на «Сегодня»
    /// и закрыть открытые экраны. false — день сменился, пока приложение было открыто: тихо обновляем дату.
    var isFullReset = false
}

enum DayRollover {
    /// Сменился ли календарный день с момента `last` (по часовому поясу пользователя на текущий момент).
    static func hasDayChanged(since last: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        !calendar.isDate(last, inSameDayAs: now)
    }
}
