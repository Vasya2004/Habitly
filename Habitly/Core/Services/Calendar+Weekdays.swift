import Foundation

extension Calendar {
    /// Однобуквенные названия дней недели, начиная с понедельника, — на языке пользователя.
    var mondayFirstVeryShortWeekdaySymbols: [String] {
        let symbols = veryShortStandaloneWeekdaySymbols // индекс 0 = воскресенье
        return Array(symbols[1...]) + [symbols[0]]
    }
}
