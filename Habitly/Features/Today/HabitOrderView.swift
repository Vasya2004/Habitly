import SwiftUI
import SwiftData

/// Экран «Порядок привычек»: ручки справа, привычки перетаскиваются. Порядок общий для «Сегодня» и виджетов.
/// При разделении по времени суток привычки переставляются внутри своего блока.
struct HabitOrderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @AppStorage(DisplayPreferences.groupByTimeKey) private var groupByTime = true

    @Query private var allHabits: [Habit]
    @State private var habitPendingDeletion: Habit?

    private var activeHabits: [Habit] {
        HabitOrdering.sorted(allHabits.filter { !$0.isArchived })
    }

    private let timeOrder: [TimeOfDay] = [.morning, .afternoon, .evening, .anytime]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(groupByTime
                         ? String(localized: "Перетащите привычки за ручку справа. Порядок меняется внутри каждого блока времени суток.")
                         : String(localized: "Перетащите привычки за ручку справа, чтобы изменить порядок на экране «Сегодня»."))
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText(for: scheme))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    if activeHabits.contains(where: { !isShownToday($0) }) {
                        Text("Приглушённые привычки сегодня не показываются на главном экране: у них другие дни недели или они на паузе. Лишние можно удалить смахиванием.")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.secondaryText(for: scheme))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }

                if groupByTime {
                    ForEach(timeOrder, id: \.self) { time in
                        let items = activeHabits.filter { $0.timeOfDay == time }
                        if !items.isEmpty {
                            Section {
                                orderRows(items)
                            } header: {
                                Label(time.title, systemImage: time.symbol)
                                    .font(Typography.subheadline)
                                    .foregroundStyle(Theme.primaryText(for: scheme))
                            }
                        }
                    }
                } else {
                    Section {
                        orderRows(activeHabits)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundGradient(for: scheme).ignoresSafeArea())
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Порядок привычек")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }.fontWeight(.semibold)
                }
            }
            .alert("Удалить привычку?", isPresented: Binding(
                get: { habitPendingDeletion != nil },
                set: { if !$0 { habitPendingDeletion = nil } }
            )) {
                Button("Отмена", role: .cancel) { habitPendingDeletion = nil }
                Button("Удалить", role: .destructive) {
                    if let habit = habitPendingDeletion { delete(habit) }
                    habitPendingDeletion = nil
                }
            } message: {
                Text("Вся история выполнения будет удалена без возможности восстановления.")
            }
        }
    }

    /// Показывается ли привычка сегодня на главном экране (не на паузе и запланирована на сегодняшний день).
    private func isShownToday(_ habit: Habit) -> Bool {
        !habit.isPaused && habit.schedule.isActive(on: .now, calendar: .current)
    }

    /// Краткое описание расписания: дни недели или «N раз в неделю».
    private func scheduleSummary(_ habit: Habit) -> String? {
        switch habit.schedule.type {
        case .everyDay:
            return nil
        case .daysOfWeek:
            let symbols = Calendar.current.shortStandaloneWeekdaySymbols // индекс 0 = воскресенье
            return [2, 3, 4, 5, 6, 7, 1]
                .filter { habit.schedule.weekdays.contains($0) }
                .map { symbols[$0 - 1] }
                .joined(separator: ", ")
        case .timesPerWeek:
            return String(localized: "\(habit.schedule.timesPerWeek) раз в неделю")
        }
    }

    private func delete(_ habit: Habit) {
        Task { await NotificationService.shared.cancelNotifications(for: habit) }
        modelContext.delete(habit)
        try? modelContext.save()
        WidgetRefreshService.reloadAll()
        Haptics.shared.warning()
    }

    private func orderRows(_ items: [Habit]) -> some View {
        ForEach(items) { habit in
            row(habit)
        }
        .onMove { source, destination in
            HabitOrdering.move(items, from: source, to: destination, allHabits: allHabits)
            try? modelContext.save()
            WidgetRefreshService.reloadAll()
            Haptics.shared.selectionChanged()
        }
        .onDelete { offsets in
            if let index = offsets.first, items.indices.contains(index) {
                habitPendingDeletion = items[index]
            }
        }
    }

    private func row(_ habit: Habit) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle().fill(habit.accentColor.gradient)
                HabitIconView(icon: habit.icon, size: 22)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(Typography.headline)
                    .foregroundStyle(Theme.primaryText(for: scheme))
                    .lineLimit(1)
                if habit.isPaused {
                    Text("На паузе")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText(for: scheme))
                } else if let summary = scheduleSummary(habit) {
                    Text(summary)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText(for: scheme))
                        .lineLimit(1)
                }
            }
        }
        .opacity(isShownToday(habit) ? 1 : 0.5)
        .padding(.vertical, 2)
    }
}
