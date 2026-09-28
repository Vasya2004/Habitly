import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var profiles: [Profile]

    @State private var viewModel = TodayViewModel()
    @State private var habitPendingDeletion: Habit?
    @State private var habitPendingEdit: Habit?
    @State private var showConfetti = false

    private var profile: Profile? { profiles.first }
    private var calendar: Calendar { .current }

    private var greeting: String {
        let hour = calendar.component(.hour, from: .now)
        let base: String
        switch hour {
        case 5..<12: base = "Доброе утро"
        case 12..<17: base = "Добрый день"
        case 17..<23: base = "Добрый вечер"
        default: base = "Доброй ночи"
        }
        let name = profile?.name.isEmpty == false ? profile!.name : nil
        return name.map { "\(base), \($0)!" } ?? "\(base)!"
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM, EEEE"
        return formatter.string(from: viewModel.selectedDate).capitalized
    }

    private var groups: [(time: TimeOfDay, habits: [Habit])] {
        viewModel.groupedHabits(from: habits)
    }

    private var dayProgress: (completed: Int, total: Int) {
        viewModel.dayProgress(for: habits)
    }

    var body: some View {
        ZStack {
            if habits.isEmpty {
                emptyState
            } else {
                content
            }

            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
            }
        }
        .onAppear(perform: ensureProfile)
        .onChange(of: viewModel.celebrationTrigger) {
            showConfetti = true
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                showConfetti = false
            }
        }
        .alert("Удалить привычку?", isPresented: Binding(get: { habitPendingDeletion != nil }, set: { if !$0 { habitPendingDeletion = nil } })) {
            Button("Отмена", role: .cancel) { habitPendingDeletion = nil }
            Button("Удалить", role: .destructive) {
                if let habit = habitPendingDeletion {
                    viewModel.delete(habit, context: modelContext)
                }
                habitPendingDeletion = nil
            }
        } message: {
            Text("Вся история выполнения этой привычки будет удалена без возможности восстановления.")
        }
        .sheet(item: $habitPendingEdit) { habit in
            HabitEditorView(mode: .edit(habit))
        }
    }

    private var content: some View {
        List {
            Section {
                header
                    .plainRow(top: Spacing.sm, bottom: Spacing.md)
                WeekStrip(selectedDate: $viewModel.selectedDate, weekStartsMonday: profile?.weekStartsMonday ?? true)
                    .plainRow(bottom: Spacing.md)
                progressRingSection
                    .plainRow(bottom: Spacing.sm)
            }

            ForEach(groups, id: \.time) { group in
                Section {
                    if !viewModel.collapsedSections.contains(group.time) {
                        ForEach(group.habits) { habit in
                            row(for: habit)
                        }
                    }
                } header: {
                    sectionHeader(group)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .padding(.bottom, 70)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greeting)
                .font(Typography.largeTitle)
                .foregroundStyle(Theme.primaryText(for: scheme))
            Text(dateText)
                .font(Typography.subheadline)
                .foregroundStyle(Theme.secondaryText(for: scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressRingSection: some View {
        let progress = dayProgress
        let fraction = progress.total > 0 ? Double(progress.completed) / Double(progress.total) : 0

        return HStack(spacing: Spacing.md) {
            ZStack {
                ProgressRing(progress: fraction, lineWidth: 12)
                VStack(spacing: 0) {
                    Text("\(progress.completed)")
                        .font(Typography.bigNumber)
                        .foregroundStyle(Theme.primaryText(for: scheme))
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : Motion.spring, value: progress.completed)
                    Text("из \(progress.total)")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText(for: scheme))
                }
            }
            .frame(width: 108, height: 108)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(progress.total == 0 ? "На сегодня ничего не запланировано" : progressHeadline(fraction: fraction))
                    .font(Typography.headline)
                    .foregroundStyle(Theme.primaryText(for: scheme))
                Text("Привычек выполнено сегодня")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText(for: scheme))
            }
            Spacer()
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    private func progressHeadline(fraction: Double) -> String {
        switch fraction {
        case 1: return "Идеальный день! 🎉"
        case 0.5...: return "Больше половины позади"
        case 0.0001...: return "Хорошее начало"
        default: return "Пора начинать"
        }
    }

    private func sectionHeader(_ group: (time: TimeOfDay, habits: [Habit])) -> some View {
        let isCollapsed = viewModel.collapsedSections.contains(group.time)
        return Button {
            withAnimation(Motion.spring) {
                if isCollapsed { viewModel.collapsedSections.remove(group.time) }
                else { viewModel.collapsedSections.insert(group.time) }
            }
        } label: {
            HStack {
                Image(systemName: group.time.symbol)
                Text(group.time.title)
                Spacer()
                Text("\(group.habits.count)")
                    .foregroundStyle(Theme.secondaryText(for: scheme))
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(isCollapsed ? -90 : 0))
            }
            .font(Typography.subheadline)
            .foregroundStyle(Theme.primaryText(for: scheme))
        }
        .buttonStyle(.plain)
    }

    private func row(for habit: Habit) -> some View {
        HabitCard(
            icon: habit.icon,
            title: habit.name,
            subtitle: viewModel.progressText(for: habit),
            color: habit.accentColor,
            streak: habit.streakStats(asOf: viewModel.selectedDate).currentStreak,
            progress: viewModel.progress(for: habit),
            isCompleted: viewModel.isCompleted(habit),
            showsStepper: habit.type != .boolean,
            onIncrement: { viewModel.increment(habit, context: modelContext, allHabits: habits) },
            onDecrement: { viewModel.decrement(habit, context: modelContext) },
            onToggle: { viewModel.toggleBoolean(habit, context: modelContext, allHabits: habits) }
        )
        .contentShape(Rectangle())
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                if habit.type == .boolean {
                    viewModel.toggleBoolean(habit, context: modelContext, allHabits: habits)
                } else {
                    viewModel.increment(habit, context: modelContext, allHabits: habits)
                }
            } label: {
                Label("Выполнить", systemImage: "checkmark")
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                viewModel.skip(habit, context: modelContext)
            } label: {
                Label("Пропустить", systemImage: "arrow.uturn.forward")
            }
            .tint(.orange)
            Button {
                habitPendingEdit = habit
            } label: {
                Label("Изменить", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .contextMenu {
            Button {
                habitPendingEdit = habit
            } label: {
                Label("Изменить", systemImage: "pencil")
            }
            Button {
                viewModel.togglePause(habit, context: modelContext)
            } label: {
                Label(habit.isPaused ? "Возобновить" : "Поставить на паузу", systemImage: habit.isPaused ? "play.fill" : "pause.fill")
            }
            Button(role: .destructive) {
                habitPendingDeletion = habit
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            EmptyStateView(
                symbol: "sparkles",
                title: "Пока пусто",
                message: "Добавьте первую привычку, чтобы начать формировать полезные ритуалы",
                actionTitle: nil,
                action: nil
            )
            Spacer()
        }
    }

    private func ensureProfile() {
        guard profiles.isEmpty else { return }
        modelContext.insert(Profile())
        try? modelContext.save()
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Habit.self, HabitLog.self, Profile.self, Achievement.self], inMemory: true)
}
