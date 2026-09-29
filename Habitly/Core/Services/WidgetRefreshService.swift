import SwiftData
import WidgetKit

/// Просит систему перерисовать таймлайны виджетов после изменений в данных.
/// Если App Group недоступна, дополнительно кладёт свежий снимок в общий Keychain.
enum WidgetRefreshService {
    private static var container: ModelContainer?

    static func configure(container: ModelContainer) {
        self.container = container
    }

    static func reloadAll() {
        publishSnapshotIfNeeded()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Применяет нажатия, сделанные на виджете, пока приложение было закрыто (режим без App Group).
    static func applyPendingWidgetToggles() {
        guard !SharedModelContainer.isAppGroupAvailable, let container else { return }
        let pending = WidgetSnapshotKeychain.readPendingToggles()
        guard !pending.isEmpty else { return }
        WidgetSnapshotKeychain.clearPendingToggles()
        let context = ModelContext(container)
        for id in pending { HabitToggler.toggleToday(habitID: id, context: context) }
        reloadAll()
    }

    private static func publishSnapshotIfNeeded() {
        guard !SharedModelContainer.isAppGroupAvailable, let container else { return }
        WidgetSnapshotKeychain.writeSnapshot(HabitlyWidgetData.load(context: ModelContext(container)))
    }
}
