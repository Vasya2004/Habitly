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
        }
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
                }
            }
        }
        .padding(.vertical, 2)
    }
}
