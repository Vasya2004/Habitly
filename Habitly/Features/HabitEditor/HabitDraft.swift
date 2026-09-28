import Foundation

/// Черновик привычки, редактируемый в HabitEditorView. Отделён от модели SwiftData,
/// чтобы отмена редактирования не оставляла частичных изменений в базе.
struct HabitDraft {
    var name: String = ""
    var icon: String = "⭐️"
    var colorIndex: Int = 0
    var type: HabitType = .boolean
    var goalValue: Double = 1
    var unit: String = ""
    var scheduleType: ScheduleType = .everyDay
    var weekdays: Set<Int> = Set(1...7)
    var timesPerWeek: Int = 3
    var timeOfDay: TimeOfDay = .anytime
    var reminders: [Date] = []
    var note: String = ""

    var schedule: HabitSchedule {
        HabitSchedule(type: scheduleType, weekdays: weekdays, timesPerWeek: timesPerWeek)
    }

    init() {}

    init(habit: Habit) {
        name = habit.name
        icon = habit.icon
        colorIndex = habit.colorIndex
        type = habit.type
        goalValue = habit.goalValue
        unit = habit.unit
        scheduleType = habit.schedule.type
        weekdays = habit.schedule.weekdays
        timesPerWeek = habit.schedule.timesPerWeek
        timeOfDay = habit.timeOfDay
        reminders = habit.reminders
        note = habit.note
    }

    init(template: HabitTemplate) {
        name = template.name
        icon = template.icon
        colorIndex = template.colorIndex
        type = template.type
        goalValue = template.goalValue
        unit = template.unit
        scheduleType = template.schedule.type
        weekdays = template.schedule.weekdays
        timesPerWeek = template.schedule.timesPerWeek
        timeOfDay = template.timeOfDay
    }

    enum ValidationError: LocalizedError {
        case emptyName
        case invalidGoal
        case missingUnit
        case noWeekdaysSelected
        case invalidTimesPerWeek

        var errorDescription: String? {
            switch self {
            case .emptyName: return "Введите название привычки"
            case .invalidGoal: return "Цель должна быть больше нуля"
            case .missingUnit: return "Укажите единицу измерения"
            case .noWeekdaysSelected: return "Выберите хотя бы один день недели"
            case .invalidTimesPerWeek: return "Укажите от 1 до 7 раз в неделю"
            }
        }
    }

    func validate() -> ValidationError? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .emptyName }
        if type != .boolean {
            if goalValue <= 0 { return .invalidGoal }
            if unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .missingUnit }
        }
        if scheduleType == .daysOfWeek && weekdays.isEmpty { return .noWeekdaysSelected }
        if scheduleType == .timesPerWeek && !(1...7).contains(timesPerWeek) { return .invalidTimesPerWeek }
        return nil
    }

    var isValid: Bool { validate() == nil }
}

extension HabitDraft.ValidationError: Equatable {}
