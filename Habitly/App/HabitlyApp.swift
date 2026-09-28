import SwiftUI
import SwiftData
import UserNotifications

@main
struct HabitlyApp: App {
    let container: ModelContainer
    private let notificationDelegate: NotificationDelegate

    init() {
        do {
            container = try ModelContainer(
                for: Habit.self, HabitLog.self, Profile.self, Achievement.self
            )
        } catch {
            fatalError("Не удалось создать ModelContainer: \(error)")
        }

        notificationDelegate = NotificationDelegate(container: container)
        UNUserNotificationCenter.current().delegate = notificationDelegate
        NotificationService.shared.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
