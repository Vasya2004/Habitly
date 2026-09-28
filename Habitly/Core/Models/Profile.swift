import Foundation
import SwiftData

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

    init(
        name: String = "",
        avatarEmoji: String = "🙂",
        xp: Int = 0,
        level: Int = 1,
        streakFreezesLeft: Int = 2,
        lastFreezeRefillMonth: Date? = nil,
        weekStartsMonday: Bool = true,
        hapticsEnabled: Bool = true,
        createdAt: Date = .now
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
    }
}
