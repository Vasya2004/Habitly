import Foundation
import SwiftData

@Model
final class HabitLog {
    var id: UUID = UUID()
    var date: Date = Date.now
    var value: Double = 0
    var isSkipped: Bool = false
    var isFrozen: Bool = false
    var note: String = ""
    /// Момент фактической отметки — в отличие от `date` (день, за который засчитывается
    /// выполнение) хранит реальное время, чтобы считать достижения "ранняя пташка"/"полуночник".
    var completedAt: Date = Date.now
    /// Защищает от повторного начисления/списания XP при многократном тапе по чекбоксу.
    var xpAwarded: Bool = false
    var habit: Habit?

    init(
        id: UUID = UUID(),
        date: Date,
        value: Double = 0,
        isSkipped: Bool = false,
        isFrozen: Bool = false,
        note: String = "",
        completedAt: Date = .now,
        xpAwarded: Bool = false,
        habit: Habit? = nil
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.value = value
        self.isSkipped = isSkipped
        self.isFrozen = isFrozen
        self.note = note
        self.completedAt = completedAt
        self.xpAwarded = xpAwarded
        self.habit = habit
    }
}
