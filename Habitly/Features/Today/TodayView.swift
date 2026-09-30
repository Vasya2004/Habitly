import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .largeTitle) private var ringSize: CGFloat = 108

    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var profiles: [Profile]

    @State private var viewModel = TodayViewModel()
    @State private var habitPendingDeletion: Habit?
    @State private var habitPendingEdit: Habit?
    @State private var showConfetti = false
    @State private var navigationPath = NavigationPath()

    private var profile: Profile? { profiles.first }
    private var calendar: Calendar { .current }

    private var greeting: String {
        let hour = calendar.component(.hour, from: .now)
        let base: String
        switch hour {
        case 5..<12: base = String(localized: "Доброе утро")
        case 12..<17: base = String(localized: "Добрый день")
        case 17..<23: base = String(localized: "Добрый вечер")
        default: base = String(localized: "Доброй ночи")
        }
        let name = profile?.name.isEmpty == false ? profile!.name : nil
        return name.map { String(localized: "\(base), \($0)!") } ?? String(localized: "\(base)!")
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("d MMMM EEEE")
        let text = formatter.string(from: viewModel.selectedDate)
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    private var groups: [(time: TimeOfDay, habits: [Habit])] {
        viewModel.groupedHabits(from: habits)
    }

    private var dayProgress: (completed: Int, total: Int) {
        viewModel.dayProgress(for: habits)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
            .navigationDestination(for: Habit.self) { habit in
                HabitDetailView(habit: habit)
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
        .fullScreenCover(isPresented: Binding(
            get: { !viewModel.pendingAchievements.isEmpty },
            set: { if !$0 { viewModel.pendingAchievements.removeFirst() } }
        )) {
            if let kind = viewModel.pendingAchievements.first {
                AchievementUnlockedView(kind: kind) {
                    viewModel.pendingAchievements.removeFirst()
                }
            }
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
                    ForEach(group.habits) { habit in
                        row(for: habit)
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
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)
            Text(dateText)
                .font(Typography.subheadline)
                .foregroundStyle(Theme.secondaryText(for: scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressRingSection: some View {
        let progress = dayProgress
        let fraction = progress.total > 0 ? Double(progress.completed) / Double(progress.total) : 0

        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.md))
            : AnyLayout(HStackLayout(spacing: Spacing.md))

        return layout {
            ZStack {
                ProgressRing(progress: fraction, lineWidth: 12)
                VStack(spacing: 0) {
                    Text("\(progress.completed)")
                        .font(Typography.bigNumber)
                        .foregroundStyle(Theme.primaryText(for: scheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : Motion.spring, value: progress.completed)
                    Text("из \(progress.total)")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText(for: scheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(.horizontal, 22)
            }
            .frame(width: ringSize, height: ringSize)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Выполнено \(progress.completed) из \(progress.total)")

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(progress.total == 0 ? String(localized: "На сегодня ничего не запланировано") : progressHeadline(fraction: fraction))
                    .font(Typography.headline)
                    .foregroundStyle(Theme.primaryText(for: scheme))
                Text("Привычек выполнено сегодня")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText(for: scheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    private func progressHeadline(fraction: Double) -> String {
        switch fraction {
        case 1: return String(localized: "Идеальный день! 🎉")
        case 0.5...: return String(localized: "Больше половины позади")
        case 0.0001...: return String(localized: "Хорошее начало")
        default: return String(localized: "Пора начинать")
        }
    }

    private func sectionHeader(_ group: (time: TimeOfDay, habits: [Habit])) -> some View {
        HStack {
            Image(systemName: group.time.symbol)
            Text(group.time.title)
            Spacer()
            Text("\(group.habits.count)")
                .foregroundStyle(Theme.secondaryText(for: scheme))
        }
        .font(Typography.subheadline)
        .foregroundStyle(Theme.primaryText(for: scheme))
    }

    private func row(for habit: Habit) -> some View {
        HabitCard(
            icon: habit.icon,
            title: habit.name,
            subtitle: viewModel.progressText(for: habit),
            color: habit.accentColor,
            streak: habit.streakStatsWithFreezes(asOf: viewModel.selectedDate).currentStreak,
            progress: viewModel.progress(for: habit),
            isCompleted: viewModel.isCompleted(habit),
            showsStepper: habit.type != .boolean,
            onIncrement: { viewModel.increment(habit, context: modelContext, allHabits: habits, profile: profile) },
            onDecrement: { viewModel.decrement(habit, context: modelContext, profile: profile) },
            onToggle: { viewModel.toggleBoolean(habit, context: modelContext, allHabits: habits, profile: profile) }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            navigationPath.append(habit)
        }
        .accessibilityAction(named: Text("Открыть детали")) {
            navigationPath.append(habit)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                if habit.type == .boolean {
                    viewModel.toggleBoolean(habit, context: modelContext, allHabits: habits, profile: profile)
                } else {
                    viewModel.increment(habit, context: modelContext, allHabits: habits, profile: profile)
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
                Label(habit.isPaused ? String(localized: "Возобновить") : String(localized: "Поставить на паузу"), systemImage: habit.isPaused ? "play.fill" : "pause.fill")
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
