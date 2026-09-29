import Foundation
import SwiftData

/// Общий SwiftData-контейнер в App Group — используется и основным приложением, и виджетами,
/// чтобы оба процесса читали и писали один и тот же файл базы данных.
enum SharedModelContainer {
    static let appGroupID = "group.com.danko.habitly"

    /// false, если App Group недоступна (нет в профиле подписи, например при бесплатном аккаунте).
    static var isAppGroupAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil
    }

    static let schema = Schema([Habit.self, HabitLog.self, Profile.self, Achievement.self])

    static func make() -> ModelContainer {
        let configuration: ModelConfiguration
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let storeURL = groupURL.appendingPathComponent("Habitly.sqlite")
            configuration = ModelConfiguration(schema: schema, url: storeURL)
        } else {
            // App Group недоступна (например, при локальной разработке без подписи) —
            // используем контейнер приложения по умолчанию, чтобы приложение не падало.
            configuration = ModelConfiguration(schema: schema)
        }

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Не удалось создать общий ModelContainer: \(error)")
        }
    }
}
