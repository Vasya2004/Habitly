import Foundation

/// Экспортирует привычки и историю выполнения в CSV или JSON.
enum DataExportService {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func exportCSV(habits: [Habit]) -> String {
        var lines = ["habit,date,type,value,goal,unit,completed,skipped,note"]
        for habit in habits {
            for log in habit.logs.sorted(by: { $0.date < $1.date }) {
                let completed = habit.isLogCompleted(log)
                let fields: [String] = [
                    csvField(habit.name),
                    isoFormatter.string(from: log.date),
                    habit.type.rawValue,
                    String(log.value),
                    String(habit.goalValue),
                    csvField(habit.unit),
                    completed ? "true" : "false",
                    log.isSkipped ? "true" : "false",
                    csvField(log.note)
                ]
                lines.append(fields.joined(separator: ","))
            }
        }
        return lines.joined(separator: "\n")
    }

    static func exportJSON(habits: [Habit]) -> String {
        let payload = habits.map { habit -> [String: Any] in
            [
                "name": habit.name,
                "icon": habit.icon,
                "type": habit.type.rawValue,
                "goalValue": habit.goalValue,
                "unit": habit.unit,
                "createdAt": isoFormatter.string(from: habit.createdAt),
                "logs": habit.logs.sorted(by: { $0.date < $1.date }).map { log -> [String: Any] in
                    [
                        "date": isoFormatter.string(from: log.date),
                        "value": log.value,
                        "completed": habit.isLogCompleted(log),
                        "skipped": log.isSkipped,
                        "note": log.note
                    ]
                }
            ]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else { return "[]" }
        return string
    }

    private static func csvField(_ raw: String) -> String {
        guard raw.contains(",") || raw.contains("\"") || raw.contains("\n") else { return raw }
        return "\"\(raw.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    /// Пишет экспорт во временный файл и возвращает его URL — удобно для ShareLink.
    static func writeTempFile(contents: String, filename: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
