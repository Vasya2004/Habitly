import Foundation
import SwiftData

enum AchievementKind: String, Codable, CaseIterable, Identifiable {
    case firstWeek
    case streak30
    case streak100
    case completions100
    case earlyBird
    case nightOwl
    case perfectWeek
    case levelFive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstWeek: return String(localized: "Первая неделя")
        case .streak30: return String(localized: "Стрик 30 дней")
        case .streak100: return String(localized: "Стрик 100 дней")
        case .completions100: return String(localized: "100 выполнений")
        case .earlyBird: return String(localized: "Ранняя пташка")
        case .nightOwl: return String(localized: "Полуночник")
        case .perfectWeek: return String(localized: "Идеальная неделя")
        case .levelFive: return String(localized: "5 уровень")
        }
    }

    var subtitle: String {
        switch self {
        case .firstWeek: return String(localized: "7 дней подряд с приложением")
        case .streak30: return String(localized: "Держите стрик 30 дней")
        case .streak100: return String(localized: "Держите стрик 100 дней")
        case .completions100: return String(localized: "Выполните привычки 100 раз")
        case .earlyBird: return String(localized: "10 привычек выполнены до 8 утра")
        case .nightOwl: return String(localized: "10 привычек выполнены после 22:00")
        case .perfectWeek: return String(localized: "Все привычки за 7 дней подряд")
        case .levelFive: return String(localized: "Достигните 5 уровня")
        }
    }

    var symbol: String {
        switch self {
        case .firstWeek: return "flag.checkered"
        case .streak30: return "flame.fill"
        case .streak100: return "flame.circle.fill"
        case .completions100: return "checkmark.seal.fill"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .perfectWeek: return "star.circle.fill"
        case .levelFive: return "crown.fill"
        }
    }
}

@Model
final class Achievement {
    var kindRaw: String
    var unlockedAt: Date

    init(kind: AchievementKind, unlockedAt: Date = .now) {
        self.kindRaw = kind.rawValue
        self.unlockedAt = unlockedAt
    }

    var kind: AchievementKind {
        AchievementKind(rawValue: kindRaw) ?? .firstWeek
    }
}
