import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var icon: String
    var colorIndex: Int
    var typeRaw: String
    var goalValue: Double
    var unit: String
    var scheduleData: Data
    var timeOfDayRaw: String
    var reminders: [Date]
    var note: String
    var createdAt: Date
    var isArchived: Bool
    var isPaused: Bool
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog] = []

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "star.fill",
        colorIndex: Int = 0,
        type: HabitType = .boolean,
        goalValue: Double = 1,
        unit: String = "",
        schedule: HabitSchedule = .everyDay,
        timeOfDay: TimeOfDay = .anytime,
        reminders: [Date] = [],
        note: String = "",
        createdAt: Date = .now,
        isArchived: Bool = false,
        isPaused: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorIndex = colorIndex
        self.typeRaw = type.rawValue
        self.goalValue = goalValue
        self.unit = unit
        self.scheduleData = (try? JSONEncoder().encode(schedule)) ?? Data()
        self.timeOfDayRaw = timeOfDay.rawValue
        self.reminders = reminders
        self.note = note
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.isPaused = isPaused
        self.sortOrder = sortOrder
    }

    var type: HabitType {
        get { HabitType(rawValue: typeRaw) ?? .boolean }
        set { typeRaw = newValue.rawValue }
    }

    var timeOfDay: TimeOfDay {
        get { TimeOfDay(rawValue: timeOfDayRaw) ?? .anytime }
        set { timeOfDayRaw = newValue.rawValue }
    }

    var schedule: HabitSchedule {
        get { (try? JSONDecoder().decode(HabitSchedule.self, from: scheduleData)) ?? .everyDay }
        set { scheduleData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var accentColor: HabitColor { HabitColor.palette[colorIndex % HabitColor.palette.count] }
}
