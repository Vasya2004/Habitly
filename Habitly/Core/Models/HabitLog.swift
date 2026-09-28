import Foundation
import SwiftData

@Model
final class HabitLog {
    var id: UUID
    var date: Date
    var value: Double
    var isSkipped: Bool
    var note: String
    var habit: Habit?

    init(
        id: UUID = UUID(),
        date: Date,
        value: Double = 0,
        isSkipped: Bool = false,
        note: String = "",
        habit: Habit? = nil
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.value = value
        self.isSkipped = isSkipped
        self.note = note
        self.habit = habit
    }
}
