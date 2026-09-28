import SwiftUI
import SwiftData

/// Редактирование записи привычки за конкретный (обычно прошлый) день:
/// отметка выполнения/пропуска, значение, короткая заметка и заморозка стрика.
struct DayLogEditorView: View {
    let habit: Habit
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Query private var profiles: [Profile]

    @State private var value: Double
    @State private var isSkipped: Bool
    @State private var note: String
    @State private var isFrozen: Bool

    private let calendar: Calendar = .current
    private var profile: Profile? { profiles.first }

    init(habit: Habit, date: Date) {
        self.habit = habit
        self.date = date
        let existing = habit.log(on: date)
        _value = State(initialValue: existing?.value ?? 0)
        _isSkipped = State(initialValue: existing?.isSkipped ?? false)
        _note = State(initialValue: existing?.note ?? "")
        _isFrozen = State(initialValue: existing?.isFrozen ?? false)
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }

    private var canOfferFreeze: Bool {
        !calendar.isDateInToday(date) && date < calendar.startOfDay(for: .now) && !isFrozen && value < habit.goalValue
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

                if isFrozen {
                    Section {
                        Label("Этот день защищён заморозкой стрика", systemImage: "snowflake")
                            .foregroundStyle(Color(hex: "3ABEEB"))
                    }
                } else if canOfferFreeze {
                    Section {
                        Button {
                            useFreeze()
                        } label: {
                            Label(
                                (profile?.streakFreezesLeft ?? 0) > 0 ? "Заморозить этот день" : "Заморозки закончились",
                                systemImage: "snowflake"
                            )
                        }
                        .disabled((profile?.streakFreezesLeft ?? 0) <= 0)
                    } footer: {
                        Text("Осталось заморозок в этом месяце: \(profile?.streakFreezesLeft ?? 0). Заморозка сохранит стрик, даже если день пропущен.")
                    }
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

    private func useFreeze() {
        guard let profile, profile.streakFreezesLeft > 0 else { return }
        profile.streakFreezesLeft -= 1
        isFrozen = true
        isSkipped = false
        Haptics.shared.success()
    }

    private func save() {
        let entry: HabitLog
        if let existing = habit.log(on: date) {
            entry = existing
        } else {
            entry = HabitLog(date: date, habit: habit)
            habit.logs.append(entry)
            modelContext.insert(entry)
        }
        entry.value = isSkipped ? 0 : value
        entry.isSkipped = isSkipped
        entry.isFrozen = isFrozen
        entry.note = note

        try? modelContext.save()
        Haptics.shared.success()
        if calendar.isDateInToday(date) {
            Task { await NotificationService.shared.cancelTodayNotification(for: habit) }
        }
        dismiss()
    }
}

#Preview {
    let habit = Habit(name: "Пить воду", icon: "💧", colorIndex: 1, type: .count, goalValue: 8, unit: "стаканов")
    return DayLogEditorView(habit: habit, date: .now)
        .modelContainer(for: [Habit.self, HabitLog.self, Profile.self, Achievement.self], inMemory: true)
}
