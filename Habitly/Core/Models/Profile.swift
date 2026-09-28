import Foundation
import SwiftData

@Model
final class Profile {
    var name: String
    var avatarEmoji: String
    var xp: Int
    var level: Int
    var streakFreezesLeft: Int
    var weekStartsMonday: Bool
    var hapticsEnabled: Bool
    var createdAt: Date

    init(
        name: String = "",
        avatarEmoji: String = "🙂",
        xp: Int = 0,
        level: Int = 1,
        streakFreezesLeft: Int = 2,
        weekStartsMonday: Bool = true,
        hapticsEnabled: Bool = true,
        createdAt: Date = .now
    ) {
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.xp = xp
        self.level = level
        self.streakFreezesLeft = streakFreezesLeft
        self.weekStartsMonday = weekStartsMonday
        self.hapticsEnabled = hapticsEnabled
        self.createdAt = createdAt
    }
}
