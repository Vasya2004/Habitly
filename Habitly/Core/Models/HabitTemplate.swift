import Foundation

enum HabitCategory: String, CaseIterable, Identifiable {
    case health, productivity, sport, mind, learning

    var id: String { rawValue }

    var title: String {
        switch self {
        case .health: return "Здоровье"
        case .productivity: return "Продуктивность"
        case .sport: return "Спорт"
        case .mind: return "Ментальное здоровье"
        case .learning: return "Обучение"
        }
    }

    var symbol: String {
        switch self {
        case .health: return "heart.fill"
        case .productivity: return "checklist"
        case .sport: return "figure.run"
        case .mind: return "brain.head.profile"
        case .learning: return "book.fill"
        }
    }
}

/// Готовый шаблон привычки для быстрого добавления — из библиотеки шаблонов
/// (этап 4) и подборок онбординга (этап 9).
struct HabitTemplate: Identifiable {
    let id = UUID()
    let category: HabitCategory
    let name: String
    let icon: String
    let colorIndex: Int
    let type: HabitType
    let goalValue: Double
    let unit: String
    let schedule: HabitSchedule
    let timeOfDay: TimeOfDay

    static let all: [HabitTemplate] = [
        // Здоровье
        HabitTemplate(category: .health, name: "Пить воду", icon: "💧", colorIndex: 1, type: .count, goalValue: 8, unit: "стаканов", schedule: .everyDay, timeOfDay: .anytime),
        HabitTemplate(category: .health, name: "Спать 8 часов", icon: "😴", colorIndex: 10, type: .boolean, goalValue: 1, unit: "", schedule: .everyDay, timeOfDay: .evening),
        HabitTemplate(category: .health, name: "Витамины", icon: "💊", colorIndex: 4, type: .boolean, goalValue: 1, unit: "", schedule: .everyDay, timeOfDay: .morning),
        HabitTemplate(category: .health, name: "Прогулка", icon: "🚶", colorIndex: 3, type: .count, goalValue: 30, unit: "мин", schedule: .everyDay, timeOfDay: .anytime),

        // Продуктивность
        HabitTemplate(category: .productivity, name: "Планировать день", icon: "📝", colorIndex: 7, type: .boolean, goalValue: 1, unit: "", schedule: .everyDay, timeOfDay: .morning),
        HabitTemplate(category: .productivity, name: "Разбор почты", icon: "📧", colorIndex: 5, type: .boolean, goalValue: 1, unit: "", schedule: HabitSchedule(type: .daysOfWeek, weekdays: [2, 3, 4, 5, 6], timesPerWeek: 5), timeOfDay: .morning),
        HabitTemplate(category: .productivity, name: "Без соцсетей", icon: "📵", colorIndex: 9, type: .boolean, goalValue: 1, unit: "", schedule: .everyDay, timeOfDay: .anytime),
        HabitTemplate(category: .productivity, name: "Уборка", icon: "🧹", colorIndex: 6, type: .boolean, goalValue: 1, unit: "", schedule: HabitSchedule(type: .timesPerWeek, weekdays: [], timesPerWeek: 3), timeOfDay: .evening),

        // Спорт
        HabitTemplate(category: .sport, name: "Тренировка", icon: "🏋️", colorIndex: 5, type: .boolean, goalValue: 1, unit: "", schedule: HabitSchedule(type: .timesPerWeek, weekdays: [], timesPerWeek: 3), timeOfDay: .afternoon),
        HabitTemplate(category: .sport, name: "Бег", icon: "🏃", colorIndex: 0, type: .count, goalValue: 5, unit: "км", schedule: HabitSchedule(type: .daysOfWeek, weekdays: [2, 4, 6], timesPerWeek: 3), timeOfDay: .morning),
        HabitTemplate(category: .sport, name: "Растяжка", icon: "🧘‍♂️", colorIndex: 8, type: .timer, goalValue: 10, unit: "мин", schedule: .everyDay, timeOfDay: .evening),
        HabitTemplate(category: .sport, name: "10000 шагов", icon: "👟", colorIndex: 2, type: .count, goalValue: 10000, unit: "шагов", schedule: .everyDay, timeOfDay: .anytime),

        // Ментальное здоровье
        HabitTemplate(category: .mind, name: "Медитация", icon: "🧘", colorIndex: 8, type: .timer, goalValue: 10, unit: "мин", schedule: .everyDay, timeOfDay: .morning),
        HabitTemplate(category: .mind, name: "Дневник благодарности", icon: "🙏", colorIndex: 11, type: .boolean, goalValue: 1, unit: "", schedule: .everyDay, timeOfDay: .evening),
        HabitTemplate(category: .mind, name: "Дыхательная практика", icon: "🌬️", colorIndex: 10, type: .timer, goalValue: 5, unit: "мин", schedule: .everyDay, timeOfDay: .anytime),

        // Обучение
        HabitTemplate(category: .learning, name: "Читать книгу", icon: "📖", colorIndex: 2, type: .timer, goalValue: 20, unit: "мин", schedule: .everyDay, timeOfDay: .evening),
        HabitTemplate(category: .learning, name: "Учить язык", icon: "🗣️", colorIndex: 7, type: .timer, goalValue: 15, unit: "мин", schedule: .everyDay, timeOfDay: .anytime),
        HabitTemplate(category: .learning, name: "Слушать подкаст", icon: "🎧", colorIndex: 9, type: .boolean, goalValue: 1, unit: "", schedule: HabitSchedule(type: .timesPerWeek, weekdays: [], timesPerWeek: 3), timeOfDay: .anytime)
    ]

    static func templates(for category: HabitCategory) -> [HabitTemplate] {
        all.filter { $0.category == category }
    }
}
