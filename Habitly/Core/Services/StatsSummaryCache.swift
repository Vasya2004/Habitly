import Foundation
import SwiftData

/// Версия данных: увеличивается при любом сохранении SwiftData. Позволяет понять, что данные не менялись,
/// без обхода всех привычек и логов (обход через SwiftData-свойства стоит десятки миллисекунд).
final class DataVersion {
    static let shared = DataVersion()
    private(set) var value = 0
    private var observer: NSObjectProtocol?

    private init() {
        observer = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave, object: nil, queue: nil
        ) { [weak self] _ in
            self?.value += 1
        }
    }
}

/// Кэш сводки статистики: пересчитывает только когда изменились период, день или данные.
/// Проверка актуальности — O(1), а не обход всех логов.
final class StatsSummaryCache {
    private struct Key: Equatable {
        let version: Int
        let period: StatsPeriod
        let day: Date
        let habitCount: Int
    }

    private var key: Key?
    private var cached: StatsSummary = .empty

    func summary(habits: [Habit], period: StatsPeriod) -> StatsSummary {
        let newKey = Key(
            version: DataVersion.shared.value,
            period: period,
            day: Calendar.current.startOfDay(for: .now),
            habitCount: habits.count
        )
        if newKey != key {
            cached = StatsCalculator.summary(habits: habits, period: period)
            key = newKey
        }
        return cached
    }
}
