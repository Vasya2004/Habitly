import Foundation
import UserNotifications

enum NotificationAction: String {
    case complete = "HABIT_COMPLETE_ACTION"
    case snooze = "HABIT_SNOOZE_ACTION"
}

/// Планирует локальные уведомления по расписанию каждой привычки.
/// Не шлёт уведомление на сегодня, если привычка уже отмечена выполненной.
final class NotificationService {
    static let shared = NotificationService()

    static let categoryIdentifier = "HABIT_REMINDER"
    private static let daysAhead = 14
    private static let identifierPrefix = "habit-reminder-"

    private let center = UNUserNotificationCenter.current()
    private let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = .current
        return formatter
    }()

    /// Несколько дружелюбных, не шаблонных вариантов текста — выбираются случайно,
    /// чтобы одна и та же формулировка не повторялась каждый день.
    private let phrases: [String] = [
        String(localized: "Небольшой шаг для «%@» — и день пойдёт по плану 🌿"),
        String(localized: "«%@» уже ждёт вас. Пара минут — и готово!"),
        String(localized: "Самое время для «%@». Вы справитесь 💪"),
        String(localized: "Не забудьте про «%@» — будущее «я» скажет спасибо"),
        String(localized: "Сегодняшняя доза «%@» ещё не выполнена — исправим?"),
        String(localized: "«%@»: маленькая привычка, большой эффект со временем ✨"),
        String(localized: "Заскочите на минутку к «%@» — и закрывайте пункт"),
        String(localized: "Хороший момент, чтобы вспомнить про «%@»"),
        String(localized: "«%@» не отметится сама — но у вас всё получится"),
        String(localized: "Ежедневная забота о себе начинается с «%@»")
    ]

    private init() {}

    // MARK: - Разрешение

    var isAuthorized: Bool {
        get async {
            let settings = await center.notificationSettings()
            return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        }
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func registerCategories() {
        let complete = UNNotificationAction(identifier: NotificationAction.complete.rawValue, title: String(localized: "Выполнено"), options: [])
        let snooze = UNNotificationAction(identifier: NotificationAction.snooze.rawValue, title: String(localized: "Напомнить через час"), options: [])
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [complete, snooze],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    // MARK: - Планирование

    /// Полностью пересобирает уведомления для привычки на ближайшие 14 дней.
    func scheduleNotifications(for habit: Habit, calendar: Calendar = .current) async {
        await cancelNotifications(for: habit)

        guard !habit.isPaused, !habit.isArchived, !habit.reminders.isEmpty else { return }
        guard await isAuthorized else { return }

        let now = Date()
        let today = calendar.startOfDay(for: now)
        var usedPhraseIndices: Set<Int> = []
        var requests: [UNNotificationRequest] = []

        for dayOffset in 0..<Self.daysAhead {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            guard habit.schedule.isActive(on: day, calendar: calendar) else { continue }
            guard day >= calendar.startOfDay(for: habit.createdAt) else { continue }
            if dayOffset == 0, habit.isCompleted(on: today, calendar: calendar) { continue }

            for (reminderIndex, reminderTime) in habit.reminders.enumerated() {
                let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
                var fireComponents = calendar.dateComponents([.year, .month, .day], from: day)
                fireComponents.hour = timeComponents.hour
                fireComponents.minute = timeComponents.minute

                guard let fireDate = calendar.date(from: fireComponents), fireDate > now else { continue }

                let phraseIndex = nextPhraseIndex(excluding: usedPhraseIndices)
                usedPhraseIndices.insert(phraseIndex)
                if usedPhraseIndices.count >= phrases.count { usedPhraseIndices.removeAll() }

                let content = UNMutableNotificationContent()
                content.title = "Habitly"
                content.body = String(format: phrases[phraseIndex], habit.name)
                content.sound = .default
                content.categoryIdentifier = Self.categoryIdentifier
                content.userInfo = ["habitID": habit.id.uuidString, "dateKey": dateKeyFormatter.string(from: day)]

                let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
                let identifier = "\(Self.identifierPrefix)\(habit.id.uuidString)-\(dateKeyFormatter.string(from: day))-\(reminderIndex)"
                requests.append(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
            }
        }

        for request in requests {
            try? await center.add(request)
        }
    }

    func rescheduleAll(habits: [Habit], calendar: Calendar = .current) async {
        for habit in habits {
            await scheduleNotifications(for: habit, calendar: calendar)
        }
    }

    // MARK: - Отмена

    func cancelNotifications(for habit: Habit) async {
        let pending = await center.pendingNotificationRequests()
        let prefix = "\(Self.identifierPrefix)\(habit.id.uuidString)-"
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Отменяет только сегодняшнее уведомление(я) для привычки — вызывается сразу
    /// после того, как пользователь отметил привычку выполненной.
    func cancelTodayNotification(for habit: Habit, calendar: Calendar = .current) async {
        let pending = await center.pendingNotificationRequests()
        let todayKey = dateKeyFormatter.string(from: calendar.startOfDay(for: .now))
        let prefix = "\(Self.identifierPrefix)\(habit.id.uuidString)-\(todayKey)-"
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Разовое напоминание через час (действие "Напомнить через час").
    func scheduleSnooze(habitID: String, habitName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Habitly"
        content.body = String(format: phrases.randomElement() ?? String(localized: "Не забудьте про «%@»"), habitName)
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier
        content.userInfo = ["habitID": habitID]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: "\(Self.identifierPrefix)snooze-\(habitID)-\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        center.add(request)
    }

    private func nextPhraseIndex(excluding: Set<Int>) -> Int {
        let available = (0..<phrases.count).filter { !excluding.contains($0) }
        return available.randomElement() ?? Int.random(in: 0..<phrases.count)
    }
}
