import SwiftUI
import SwiftData
import UserNotifications

@main
struct HabitlyApp: App {
    let container: ModelContainer
    private let notificationDelegate: NotificationDelegate

    init() {
        container = SharedModelContainer.make()

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
