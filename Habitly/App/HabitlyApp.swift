import SwiftUI
import SwiftData
import UserNotifications

@main
struct HabitlyApp: App {
    let container: ModelContainer
    private let notificationDelegate: NotificationDelegate

    init() {
        container = SharedModelContainer.make()
        WidgetRefreshService.configure(container: container)

        notificationDelegate = NotificationDelegate(container: container)
        UNUserNotificationCenter.current().delegate = notificationDelegate
        NotificationService.shared.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // Ограничиваем максимальный размер шрифта: крупный текст поддерживается,
                // но самые крайние значения ломают карточки и кольца.
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        }
        .modelContainer(container)
    }
}
