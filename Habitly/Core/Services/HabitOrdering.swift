import SwiftUI
import SwiftData

enum DisplayPreferences {
    /// true — привычки на «Сегодня» разделены на блоки по времени суток; false — одним списком.
    static let groupByTimeKey = "groupHabitsByTime"
}

/// Порядок привычек: единый `sortOrder` для экрана «Сегодня», виджетов и экрана перестановки.
enum HabitOrdering {
    /// Порядок отображения: по sortOrder, при равенстве — по дате создания (детерминированно).
    static func sorted(_ habits: [Habit]) -> [Habit] {
        habits.sorted { a, b in
            if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
            if a.createdAt != b.createdAt { return a.createdAt < b.createdAt }
            return a.id.uuidString < b.id.uuidString
        }
    }

    /// sortOrder для новой привычки — в конец списка.
    static func nextSortOrder(among habits: [Habit]) -> Int {
        (habits.map(\.sortOrder).max() ?? -1) + 1
    }

    /// Делает sortOrder уникальным: 0...n-1 в текущем порядке отображения.
    static func normalize(_ habits: [Habit]) {
        for (index, habit) in sorted(habits).enumerated() where habit.sortOrder != index {
            habit.sortOrder = index
        }
    }

    /// Переставляет привычки внутри `subset` (в порядке, в котором они показаны), не затрагивая остальные:
    /// переставленные привычки занимают те же «места» sortOrder, что и раньше.
    static func move(_ subset: [Habit], from source: IndexSet, to destination: Int, allHabits: [Habit]) {
        normalize(allHabits)
        let ordered = sorted(subset)
        var reordered = ordered
        reordered.move(fromOffsets: source, toOffset: destination)
        for (habit, slot) in zip(reordered, ordered.map(\.sortOrder)) {
            habit.sortOrder = slot
        }
    }
}
