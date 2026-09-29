import AppIntents
import WidgetKit

/// Отмечает привычку выполненной/невыполненной прямо из виджета, без открытия приложения.
struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Отметить привычку"
    static var description = IntentDescription("Отмечает привычку выполненной за сегодня")

    @Parameter(title: "ID привычки")
    var habitID: String

    init() {}

    init(habitID: String) {
        self.habitID = habitID
    }

    func perform() async throws -> some IntentResult {
        if SharedModelContainer.isAppGroupAvailable {
            HabitToggler.toggleToday(habitID: habitID, context: ModelContextProvider.shared.context)
        } else {
            // Без App Group виджет не может писать в базу приложения: обновляем снимок
            // и откладываем нажатие — приложение применит его при следующем открытии.
            applyToSnapshotAndQueue()
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }

    private func applyToSnapshotAndQueue() {
        WidgetSnapshotKeychain.appendPendingToggle(habitID)
        guard let data = WidgetSnapshotKeychain.readSnapshot() else { return }
        let habits = data.habits.map { habit -> HabitSnapshot in
            guard habit.id.uuidString == habitID else { return habit }
            return HabitSnapshot(
                id: habit.id, name: habit.name, icon: habit.icon, colorIndex: habit.colorIndex,
                type: habit.type, goalValue: habit.goalValue, unit: habit.unit,
                value: habit.isCompleted ? 0 : habit.goalValue, isCompleted: !habit.isCompleted, streak: habit.streak
            )
        }
        WidgetSnapshotKeychain.writeSnapshot(HabitlyWidgetData(
            completed: habits.filter(\.isCompleted).count, total: data.total,
            bestStreak: data.bestStreak, habits: habits, week: data.week
        ))
    }
}
