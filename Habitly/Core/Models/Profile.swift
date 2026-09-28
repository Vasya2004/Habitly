import Foundation
import SwiftData

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Системная"
        case .light: return "Светлая"
        case .dark: return "Тёмная"
        }
    }

    var colorScheme: ColorSchemePreference {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Обёртка, чтобы не тянуть SwiftUI в модель данных.
enum ColorSchemePreference {
    case unspecified, light, dark
}

@Model
final class Profile {
    var name: String
    var avatarEmoji: String
    var xp: Int
    var level: Int
    var streakFreezesLeft: Int
    /// Месяц (первое число), на который последний раз пополнялись заморозки стрика —
    /// используется, чтобы выдавать по 2 заморозки раз в календарный месяц.
    var lastFreezeRefillMonth: Date?
    var weekStartsMonday: Bool
    var hapticsEnabled: Bool
    var createdAt: Date
    var hasCompletedOnboarding: Bool = false
    var appearanceRaw: String = AppearanceMode.system.rawValue

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    init(
        name: String = "",
        avatarEmoji: String = "🙂",
        xp: Int = 0,
        level: Int = 1,
        streakFreezesLeft: Int = 2,
        lastFreezeRefillMonth: Date? = nil,
        weekStartsMonday: Bool = true,
        hapticsEnabled: Bool = true,
        createdAt: Date = .now,
        hasCompletedOnboarding: Bool = false,
        appearance: AppearanceMode = .system
    ) {
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.xp = xp
        self.level = level
        self.streakFreezesLeft = streakFreezesLeft
        self.lastFreezeRefillMonth = lastFreezeRefillMonth
        self.weekStartsMonday = weekStartsMonday
        self.hapticsEnabled = hapticsEnabled
        self.createdAt = createdAt
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.appearanceRaw = appearance.rawValue
    }
}
