import Foundation
import SwiftData

struct ImportResult: Equatable {
    var habitsAdded = 0
    var habitsMerged = 0
    var logsAdded = 0

    var isEmpty: Bool { habitsAdded == 0 && logsAdded == 0 }
}

enum ImportError: LocalizedError {
    case unreadableFile

    var errorDescription: String? {
        String(localized: "Файл повреждён или не является экспортом Habitly в формате JSON.")
    }
}

/// Восстанавливает привычки и историю из JSON-экспорта. Импорт только добавляет данные:
/// существующие привычки и записи не перезаписываются, повторный импорт не создаёт дубликатов.
enum DataImportService {
    static func decode(_ data: Data) throws -> [BackupHabit] {
        let decoder = BackupCoding.makeDecoder()
        if let file = try? decoder.decode(BackupFile.self, from: data) { return file.habits }
        if let habits = try? decoder.decode([BackupHabit].self, from: data) { return habits }
        throw ImportError.unreadableFile
    }

    @discardableResult
    static func importJSON(_ data: Data, into context: ModelContext, calendar: Calendar = .current) throws -> ImportResult {
        let backup = try decode(data)
        var result = ImportResult()

        var existing = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        var nextSortOrder = (existing.map(\.sortOrder).max() ?? -1) + 1

        for item in backup {
            let habit: Habit
            if let match = existing.first(where: { matches($0, item) }) {
                habit = match
                result.habitsMerged += 1
            } else {
                habit = Habit(
                    id: item.id ?? UUID(),
                    name: item.name,
                    icon: item.icon ?? "star.fill",
                    colorIndex: item.colorIndex ?? 0,
                    type: item.type,
                    goalValue: item.goalValue,
                    unit: item.unit ?? "",
                    schedule: item.schedule ?? .everyDay,
                    timeOfDay: item.timeOfDay ?? .anytime,
                    reminders: item.reminders ?? [],
                    note: item.note ?? "",
                    createdAt: item.createdAt ?? .now,
                    isArchived: item.isArchived ?? false,
                    isPaused: item.isPaused ?? false,
                    sortOrder: item.sortOrder ?? nextSortOrder
                )
                nextSortOrder += 1
                context.insert(habit)
                existing.append(habit)
                result.habitsAdded += 1
            }

            for entry in item.logs ?? [] {
                guard habit.log(on: entry.date, calendar: calendar) == nil else { continue }
                let log = HabitLog(
                    id: entry.id ?? UUID(),
                    date: entry.date,
                    value: entry.value,
                    isSkipped: entry.skipped ?? false,
                    isFrozen: entry.frozen ?? false,
                    note: entry.note ?? "",
                    completedAt: entry.completedAt ?? entry.date,
                    habit: habit
                )
                habit.logs.append(log)
                context.insert(log)
                result.logsAdded += 1
            }
        }

        try context.save()
        return result
    }

    private static func matches(_ habit: Habit, _ item: BackupHabit) -> Bool {
        if let id = item.id { return habit.id == id }
        return habit.name.caseInsensitiveCompare(item.name) == .orderedSame && habit.type == item.type
    }
}
