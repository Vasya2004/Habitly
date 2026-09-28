import Foundation
import SwiftData
import Observation

@Observable
final class TodayViewModel {
    var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    var collapsedSections: Set<TimeOfDay> = []
    var celebrationTrigger: Int = 0
    var pendingAchievements: [AchievementKind] = []

    private let calendar = Calendar.current

    // MARK: - Чтение состояния

    func log(for habit: Habit, on date: Date? = nil) -> HabitLog? {
        let day = date ?? selectedDate
        return habit.logs.first { calendar.isDate($0.date, inSameDayAs: day) }
    }

    func isCompleted(_ habit: Habit, on date: Date? = nil) -> Bool {
        guard let log = log(for: habit, on: date), !log.isSkipped else { return false }
        switch habit.type {
        case .boolean: return log.value >= 1
        case .count, .timer: return log.value >= habit.goalValue
        }
    }

    func isSkipped(_ habit: Habit, on date: Date? = nil) -> Bool {
        log(for: habit, on: date)?.isSkipped ?? false
    }

    func progress(for habit: Habit, on date: Date? = nil) -> Double {
        let value = log(for: habit, on: date)?.value ?? 0
        guard habit.goalValue > 0 else { return value > 0 ? 1 : 0 }
        return min(value / habit.goalValue, 1)
    }

    func progressText(for habit: Habit, on date: Date? = nil) -> String {
        switch habit.type {
        case .boolean:
            return isCompleted(habit, on: date) ? "Выполнено" : "Не выполнено"
        case .count, .timer:
            let value = log(for: habit, on: date)?.value ?? 0
            let goal = habit.goalValue
            let formatter: (Double) -> String = { $0.truncatingRemainder(dividingBy: 1) == 0 ? String(Int($0)) : String(format: "%.1f", $0) }
            return "\(formatter(value)) из \(formatter(goal)) \(habit.unit)"
        }
    }

    func isScheduled(_ habit: Habit, on date: Date? = nil) -> Bool {
        habit.schedule.isActive(on: date ?? selectedDate, calendar: calendar)
    }

    /// Активные (не в архиве, не на паузе) привычки, запланированные на выбранный день,
    /// сгруппированные по времени суток в порядке утро → день → вечер → в любое время.
    func groupedHabits(from habits: [Habit]) -> [(time: TimeOfDay, habits: [Habit])] {
        let relevant = habits
            .filter { !$0.isArchived && !$0.isPaused && isScheduled($0) }
            .sorted { $0.sortOrder < $1.sortOrder }
        let order: [TimeOfDay] = [.morning, .afternoon, .evening, .anytime]
        return order.compactMap { time in
            let items = relevant.filter { $0.timeOfDay == time }
            return items.isEmpty ? nil : (time, items)
        }
    }

    func dayProgress(for habits: [Habit]) -> (completed: Int, total: Int) {
        let scheduled = habits.filter { !$0.isArchived && !$0.isPaused && isScheduled($0) }
        let completed = scheduled.filter { isCompleted($0) }.count
        return (completed, scheduled.count)
    }

    // MARK: - Мутации

    private func existingOrNewLog(for habit: Habit, context: ModelContext) -> HabitLog {
        if let existing = log(for: habit) { return existing }
        let newLog = HabitLog(date: selectedDate, habit: habit)
        habit.logs.append(newLog)
        context.insert(newLog)
        return newLog
    }

    func toggleBoolean(_ habit: Habit, context: ModelContext, allHabits: [Habit], profile: Profile?) {
        let wasCompleted = isCompleted(habit)
        let entry = existingOrNewLog(for: habit, context: context)
        entry.isSkipped = false
        entry.value = wasCompleted ? 0 : 1
        applyGamification(habit: habit, entry: entry, isCompletedNow: !wasCompleted, context: context, profile: profile, allHabits: allHabits)
        checkCelebration(allHabits: allHabits)
        if !wasCompleted { cancelTodayNotificationIfNeeded(for: habit) }
    }

    func increment(_ habit: Habit, context: ModelContext, allHabits: [Habit], profile: Profile?) {
        let wasCompleted = isCompleted(habit)
        let entry = existingOrNewLog(for: habit, context: context)
        entry.isSkipped = false
        let step = habit.type == .timer ? min(5, habit.goalValue) : 1
        entry.value = min(entry.value + step, habit.goalValue)
        let nowCompleted = isCompleted(habit)
        applyGamification(habit: habit, entry: entry, isCompletedNow: nowCompleted, context: context, profile: profile, allHabits: allHabits)
        checkCelebration(allHabits: allHabits)
        if !wasCompleted, nowCompleted { cancelTodayNotificationIfNeeded(for: habit) }
    }

    func decrement(_ habit: Habit, context: ModelContext, profile: Profile?) {
        guard let entry = log(for: habit) else { return }
        let step = habit.type == .timer ? min(5, habit.goalValue) : 1
        entry.value = max(entry.value - step, 0)
        if let profile {
            GamificationService.applyCompletion(isCompleted: habit.isLogCompleted(entry), to: entry, profile: profile)
        }
        try? context.save()
    }

    func skip(_ habit: Habit, context: ModelContext) {
        let entry = existingOrNewLog(for: habit, context: context)
        entry.isSkipped = true
        entry.value = 0
        try? context.save()
        cancelTodayNotificationIfNeeded(for: habit)
    }

    func togglePause(_ habit: Habit, context: ModelContext) {
        habit.isPaused.toggle()
        try? context.save()
        if habit.isPaused {
            Task { await NotificationService.shared.cancelNotifications(for: habit) }
        } else {
            Task { await NotificationService.shared.scheduleNotifications(for: habit) }
        }
    }

    func delete(_ habit: Habit, context: ModelContext) {
        Task { await NotificationService.shared.cancelNotifications(for: habit) }
        context.delete(habit)
        try? context.save()
    }

    private func applyGamification(habit: Habit, entry: HabitLog, isCompletedNow: Bool, context: ModelContext, profile: Profile?, allHabits: [Habit]) {
        guard let profile else {
            try? context.save()
            return
        }
        GamificationService.applyCompletion(isCompleted: isCompletedNow, to: entry, profile: profile)
        try? context.save()
        guard isCompletedNow else { return }

        let existingKinds = Set((try? context.fetch(FetchDescriptor<Achievement>()))?.map(\.kind) ?? [])
        let newlyUnlocked = GamificationService.checkAchievements(profile: profile, habits: allHabits, unlockedKinds: existingKinds)
        guard !newlyUnlocked.isEmpty else { return }
        for kind in newlyUnlocked {
            context.insert(Achievement(kind: kind))
        }
        try? context.save()
        pendingAchievements.append(contentsOf: newlyUnlocked)
    }

    private func cancelTodayNotificationIfNeeded(for habit: Habit) {
        guard calendar.isDate(selectedDate, inSameDayAs: .now) else { return }
        Task { await NotificationService.shared.cancelTodayNotification(for: habit) }
    }

    private func checkCelebration(allHabits: [Habit]) {
        guard calendar.isDate(selectedDate, inSameDayAs: .now) else { return }
        let progress = dayProgress(for: allHabits)
        guard progress.total > 0, progress.completed == progress.total else { return }
        Haptics.shared.celebration()
        celebrationTrigger += 1
    }
}
