import Foundation

enum HabitType: String, Codable, CaseIterable, Identifiable {
    case boolean
    case count
    case timer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .boolean: return String(localized: "Да / Нет")
        case .count: return String(localized: "Количество")
        case .timer: return String(localized: "Таймер")
        }
    }
}

enum ScheduleType: String, Codable, CaseIterable, Identifiable {
    case everyDay
    case daysOfWeek
    case timesPerWeek

    var id: String { rawValue }

    var title: String {
        switch self {
        case .everyDay: return String(localized: "Каждый день")
        case .daysOfWeek: return String(localized: "Дни недели")
        case .timesPerWeek: return String(localized: "X раз в неделю")
        }
    }
}

enum TimeOfDay: String, Codable, CaseIterable, Identifiable {
    case morning
    case afternoon
    case evening
    case anytime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: return String(localized: "Утро")
        case .afternoon: return String(localized: "День")
        case .evening: return String(localized: "Вечер")
        case .anytime: return String(localized: "В любое время")
        }
    }

    var symbol: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        case .anytime: return "clock.fill"
        }
    }
}

struct HabitSchedule: Codable, Equatable {
    var type: ScheduleType
    var weekdays: Set<Int>
    var timesPerWeek: Int

    static let everyDay = HabitSchedule(type: .everyDay, weekdays: Set(1...7), timesPerWeek: 7)

    func isActive(on date: Date, calendar: Calendar = .current) -> Bool {
        switch type {
        case .everyDay:
            return true
        case .daysOfWeek:
            let weekday = calendar.component(.weekday, from: date)
            return weekdays.contains(weekday)
        case .timesPerWeek:
            return true
        }
    }
}
