import Foundation

/// Формат резервной копии Habitly (JSON). Все поля, кроме имени, типа и цели, необязательны —
/// поэтому импорт читает и полные копии (версия 2), и старый упрощённый экспорт (массив привычек).
struct BackupFile: Codable {
    var app: String = "Habitly"
    var version: Int = 2
    var exportedAt: Date
    var habits: [BackupHabit]
}

struct BackupHabit: Codable {
    var id: UUID?
    var name: String
    var icon: String?
    var colorIndex: Int?
    var type: HabitType
    var goalValue: Double
    var unit: String?
    var schedule: HabitSchedule?
    var timeOfDay: TimeOfDay?
    var reminders: [Date]?
    var note: String?
    var createdAt: Date?
    var isArchived: Bool?
    var isPaused: Bool?
    var sortOrder: Int?
    var logs: [BackupLog]?
}

struct BackupLog: Codable {
    var id: UUID?
    var date: Date
    var value: Double
    var skipped: Bool?
    var frozen: Bool?
    var note: String?
    var completedAt: Date?
    /// Только для удобства чтения файла человеком — при импорте вычисляется заново.
    var completed: Bool?
}

extension BackupHabit {
    init(_ habit: Habit) {
        self.init(
            id: habit.id,
            name: habit.name,
            icon: habit.icon,
            colorIndex: habit.colorIndex,
            type: habit.type,
            goalValue: habit.goalValue,
            unit: habit.unit,
            schedule: habit.schedule,
            timeOfDay: habit.timeOfDay,
            reminders: habit.reminders,
            note: habit.note,
            createdAt: habit.createdAt,
            isArchived: habit.isArchived,
            isPaused: habit.isPaused,
            sortOrder: habit.sortOrder,
            logs: habit.logs.sorted { $0.date < $1.date }.map { log in
                BackupLog(
                    id: log.id, date: log.date, value: log.value, skipped: log.isSkipped,
                    frozen: log.isFrozen, note: log.note, completedAt: log.completedAt,
                    completed: habit.isLogCompleted(log)
                )
            }
        )
    }
}

enum BackupCoding {
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
