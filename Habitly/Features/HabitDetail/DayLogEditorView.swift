import SwiftUI
import SwiftData

/// Редактирование записи привычки за конкретный (обычно прошлый) день:
/// отметка выполнения/пропуска, значение и короткая заметка.
struct DayLogEditorView: View {
    let habit: Habit
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @State private var value: Double
    @State private var isSkipped: Bool
    @State private var note: String

    private let calendar: Calendar = .current

    init(habit: Habit, date: Date) {
        self.habit = habit
        self.date = date
        let existing = habit.log(on: date)
        _value = State(initialValue: existing?.value ?? 0)
        _isSkipped = State(initialValue: existing?.isSkipped ?? false)
        _note = State(initialValue: existing?.note ?? "")
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    switch habit.type {
                    case .boolean:
                        Toggle("Выполнено", isOn: Binding(
                            get: { value >= 1 },
                            set: { value = $0 ? 1 : 0 }
                        ))
                        .tint(habit.accentColor.start)
                    case .count, .timer:
                        Stepper(value: $value, in: 0...max(habit.goalValue * 2, 1), step: habit.type == .timer ? 5 : 1) {
                            Text("\(formattedValue) из \(formattedGoal) \(habit.unit)")
                        }
                    }

                    Toggle("Пропустить день", isOn: $isSkipped)
                        .tint(.orange)
                } header: {
                    Text(dateTitle.capitalized)
                }

                Section("Заметка") {
                    TextField("Как прошло?", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Запись дня")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: save).fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var formattedValue: String { value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value) }
    private var formattedGoal: String { habit.goalValue.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(habit.goalValue)) : String(format: "%.1f", habit.goalValue) }

    private func save() {
        if let existing = habit.log(on: date) {
            existing.value = isSkipped ? 0 : value
            existing.isSkipped = isSkipped
            existing.note = note
        } else {
            let newLog = HabitLog(date: date, value: isSkipped ? 0 : value, isSkipped: isSkipped, note: note, habit: habit)
            habit.logs.append(newLog)
            modelContext.insert(newLog)
        }
        try? modelContext.save()
        Haptics.shared.success()
        dismiss()
    }
}

#Preview {
    let habit = Habit(name: "Пить воду", icon: "💧", colorIndex: 1, type: .count, goalValue: 8, unit: "стаканов")
    return DayLogEditorView(habit: habit, date: .now)
        .modelContainer(for: [Habit.self, HabitLog.self, Profile.self, Achievement.self], inMemory: true)
}
