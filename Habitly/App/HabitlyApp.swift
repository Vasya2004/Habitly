import SwiftUI
import SwiftData

@main
struct HabitlyApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Habit.self, HabitLog.self, Profile.self, Achievement.self
            )
        } catch {
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
