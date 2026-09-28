import Foundation
import UserNotifications
import SwiftData

/// Обрабатывает действия прямо из уведомления ("Выполнено" / "Напомнить через час")
/// и показывает уведомления, даже когда приложение открыто на переднем плане.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        guard let habitIDString = response.notification.request.content.userInfo["habitID"] as? String,
              let habitID = UUID(uuidString: habitIDString) else { return }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.id == habitID })
        guard let habit = try? context.fetch(descriptor).first else { return }

        switch response.actionIdentifier {
        case NotificationAction.complete.rawValue:
            markCompleted(habit: habit, context: context)
            Task { await NotificationService.shared.cancelTodayNotification(for: habit) }
        case NotificationAction.snooze.rawValue:
            NotificationService.shared.scheduleSnooze(habitID: habitIDString, habitName: habit.name)
        default:
            break
        }
    }

    private func markCompleted(habit: Habit, context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        if let existing = habit.logs.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            existing.isSkipped = false
            existing.value = habit.type == .boolean ? 1 : habit.goalValue
        } else {
            let log = HabitLog(date: today, value: habit.type == .boolean ? 1 : habit.goalValue, habit: habit)
            habit.logs.append(log)
            context.insert(log)
        }
        try? context.save()
    }
}
