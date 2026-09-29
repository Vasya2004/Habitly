import WidgetKit

/// Просит систему перерисовать таймлайны виджетов после изменений в данных.
enum WidgetRefreshService {
    static func reloadAll() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
