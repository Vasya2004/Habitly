import SwiftUI
import SwiftData

/// Экран создания/редактирования привычки: живое превью карточки сверху,
/// библиотека шаблонов (только при создании) и поля с валидацией.
struct HabitEditorView: View {
    enum Mode {
        case create
        case edit(Habit)
    }

    let mode: Mode
    var onSaved: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @State private var draft: HabitDraft
    @State private var showValidationError = false
    @FocusState private var nameFieldFocused: Bool

    init(mode: Mode, onSaved: (() -> Void)? = nil) {
        self.mode = mode
        self.onSaved = onSaved
        switch mode {
        case .create:
            _draft = State(initialValue: HabitDraft())
        case .edit(let habit):
            _draft = State(initialValue: HabitDraft(habit: habit))
        }
    }

    private var isCreating: Bool {
        if case .create = mode { return true }
        return false
    }

    private var accentColor: HabitColor { HabitColor.palette[draft.colorIndex % HabitColor.palette.count] }

    private var previewSubtitle: String {
        switch draft.type {
        case .boolean: return "Не выполнено"
        case .count, .timer:
            let goal = draft.goalValue.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(draft.goalValue)) : String(format: "%.1f", draft.goalValue)
            return "0 из \(goal) \(draft.unit)"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    preview

                    if isCreating {
                        section(title: "Шаблоны") {
                            TemplateGalleryView { template in
                                applyTemplate(template)
                            }
                        }
                    }

                    section(title: "Название") {
                        TextField("Например, «Пить воду»", text: $draft.name)
                            .textFieldStyle(.plain)
                            .font(Typography.body)
                            .padding(Spacing.sm)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.control))
                            .focused($nameFieldFocused)
                    }

                    section(title: "Иконка") {
                        IconPickerView(selection: $draft.icon, accentColor: accentColor)
                    }

                    section(title: "Цвет") {
                        ColorPickerRow(selectedIndex: $draft.colorIndex)
                    }

                    section(title: "Тип привычки") {
                        Picker("Тип", selection: $draft.type) {
                            ForEach(HabitType.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    if draft.type != .boolean {
                        section(title: "Цель") {
                            HStack(spacing: Spacing.sm) {
                                TextField("Значение", value: $draft.goalValue, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.plain)
                                    .padding(Spacing.sm)
                                    .frame(width: 100)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.control))
                                TextField("Единица (мин, км, стаканов…)", text: $draft.unit)
                                    .textFieldStyle(.plain)
                                    .padding(Spacing.sm)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.control))
                            }
                        }
                    }

                    section(title: "Частота") {
                        ScheduleEditorView(scheduleType: $draft.scheduleType, weekdays: $draft.weekdays, timesPerWeek: $draft.timesPerWeek)
                    }

                    section(title: "Время дня") {
                        Picker("Время дня", selection: $draft.timeOfDay) {
                            ForEach(TimeOfDay.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    section(title: "Напоминания") {
                        ReminderEditorView(reminders: $draft.reminders)
                    }

                    section(title: "Зачем мне это") {
                        TextField("Например, «чтобы высыпаться и быть бодрее»", text: $draft.note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(2...4)
                            .padding(Spacing.sm)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.control))
                    }

                    if showValidationError, let error = draft.validate() {
                        Text(error.errorDescription ?? "")
                            .font(Typography.subheadline)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isCreating ? "Новая привычка" : "Изменить привычку")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: save)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(Typography.subheadline)
                .foregroundStyle(Theme.secondaryText(for: scheme))
            content()
        }
    }

    private var preview: some View {
        HabitCard(
            icon: draft.icon,
            title: draft.name.isEmpty ? "Название привычки" : draft.name,
            subtitle: previewSubtitle,
            color: accentColor,
            streak: 0,
            progress: 0,
            isCompleted: false,
            showsStepper: draft.type != .boolean,
            onIncrement: nil, onDecrement: nil, onToggle: {}
        )
        .allowsHitTesting(false)
    }

    private func applyTemplate(_ template: HabitTemplate) {
        draft = HabitDraft(template: template)
        nameFieldFocused = false
    }

    private func save() {
        guard draft.validate() == nil else {
            showValidationError = true
            Haptics.shared.warning()
            return
        }

        switch mode {
        case .create:
            let habit = Habit(
                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: draft.icon,
                colorIndex: draft.colorIndex,
                type: draft.type,
                goalValue: draft.goalValue,
                unit: draft.unit,
                schedule: draft.schedule,
                timeOfDay: draft.timeOfDay,
                reminders: draft.reminders,
                note: draft.note
            )
            modelContext.insert(habit)
        case .edit(let habit):
            habit.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            habit.icon = draft.icon
            habit.colorIndex = draft.colorIndex
            habit.type = draft.type
            habit.goalValue = draft.goalValue
            habit.unit = draft.unit
            habit.schedule = draft.schedule
            habit.timeOfDay = draft.timeOfDay
            habit.reminders = draft.reminders
            habit.note = draft.note
        }

        try? modelContext.save()
        Haptics.shared.success()
        onSaved?()
        dismiss()
    }
}

#Preview {
    HabitEditorView(mode: .create)
        .modelContainer(for: [Habit.self, HabitLog.self, Profile.self, Achievement.self], inMemory: true)
}
