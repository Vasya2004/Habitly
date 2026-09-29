import XCTest
import SwiftData
@testable import Habitly

final class DataImportTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: SharedModelContainer.schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        return ModelContext(container)
    }

    private func seedHabit(in context: ModelContext) -> Habit {
        let habit = Habit(
            name: "Бег", icon: "🏃", colorIndex: 3, type: .count, goalValue: 5, unit: "км",
            schedule: HabitSchedule(type: .timesPerWeek, weekdays: [], timesPerWeek: 3),
            timeOfDay: .morning, note: "утром"
        )
        context.insert(habit)
        for offset in 1...3 {
            let day = Calendar.current.date(byAdding: .day, value: -offset, to: .now)!
            let log = HabitLog(date: day, value: Double(offset), note: "n\(offset)", habit: habit)
            habit.logs.append(log)
            context.insert(log)
        }
        try? context.save()
        return habit
    }

    func test_roundTrip_restoresHabitSettingsAndLogs() throws {
        let source = try makeContext()
        let habit = seedHabit(in: source)
        let json = DataExportService.exportJSON(habits: [habit])

        let target = try makeContext()
        let result = try DataImportService.importJSON(Data(json.utf8), into: target)

        XCTAssertEqual(result, ImportResult(habitsAdded: 1, habitsMerged: 0, logsAdded: 3))
        let restored = try XCTUnwrap(try target.fetch(FetchDescriptor<Habit>()).first)
        XCTAssertEqual(restored.id, habit.id)
        XCTAssertEqual(restored.name, "Бег")
        XCTAssertEqual(restored.type, .count)
        XCTAssertEqual(restored.goalValue, 5)
        XCTAssertEqual(restored.colorIndex, 3)
        XCTAssertEqual(restored.timeOfDay, .morning)
        XCTAssertEqual(restored.schedule.type, .timesPerWeek)
        XCTAssertEqual(restored.schedule.timesPerWeek, 3)
        XCTAssertEqual(restored.logs.count, 3)
    }

    func test_importTwice_doesNotDuplicate() throws {
        let source = try makeContext()
        let json = DataExportService.exportJSON(habits: [seedHabit(in: source)])
        let target = try makeContext()

        try DataImportService.importJSON(Data(json.utf8), into: target)
        let second = try DataImportService.importJSON(Data(json.utf8), into: target)

        XCTAssertEqual(second, ImportResult(habitsAdded: 0, habitsMerged: 1, logsAdded: 0))
        XCTAssertEqual(try target.fetch(FetchDescriptor<Habit>()).count, 1)
        XCTAssertEqual(try target.fetch(FetchDescriptor<HabitLog>()).count, 3)
    }

    func test_import_doesNotOverwriteExistingLog() throws {
        let source = try makeContext()
        let json = DataExportService.exportJSON(habits: [seedHabit(in: source)])
        let target = try makeContext()
        try DataImportService.importJSON(Data(json.utf8), into: target)

        let habit = try XCTUnwrap(try target.fetch(FetchDescriptor<Habit>()).first)
        habit.logs.forEach { $0.value = 99 }
        try target.save()

        try DataImportService.importJSON(Data(json.utf8), into: target)
        XCTAssertTrue(habit.logs.allSatisfy { $0.value == 99 })
    }

    func test_legacyArrayFormat_isImported() throws {
        let legacy = """
        [{"name":"Вода","icon":"💧","type":"count","goalValue":8,"unit":"стаканов",
          "createdAt":"2026-01-01T10:00:00Z",
          "logs":[{"date":"2026-01-02T00:00:00Z","value":8,"completed":true,"skipped":false,"note":""}]}]
        """
        let context = try makeContext()
        let result = try DataImportService.importJSON(Data(legacy.utf8), into: context)
        XCTAssertEqual(result, ImportResult(habitsAdded: 1, habitsMerged: 0, logsAdded: 1))
    }

    func test_garbage_throwsUnreadableFile() throws {
        let context = try makeContext()
        XCTAssertThrowsError(try DataImportService.importJSON(Data("не json".utf8), into: context))
    }
}
