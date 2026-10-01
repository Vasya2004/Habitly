import XCTest
@testable import Habitly

final class HabitOrderingTests: XCTestCase {
    private func make(_ name: String, order: Int, time: TimeOfDay = .anytime, day: Int = 1) -> Habit {
        Habit(name: name, timeOfDay: time,
              createdAt: Date(timeIntervalSince1970: Double(day) * 86_400), sortOrder: order)
    }

    private func names(_ habits: [Habit]) -> [String] { HabitOrdering.sorted(habits).map(\.name) }

    func test_sorted_breaksTiesByCreationDate() {
        let a = make("A", order: 0, day: 3)
        let b = make("B", order: 0, day: 1)
        let c = make("C", order: 0, day: 2)
        XCTAssertEqual(names([a, b, c]), ["B", "C", "A"])
    }

    func test_nextSortOrder_appendsToEnd() {
        XCTAssertEqual(HabitOrdering.nextSortOrder(among: []), 0)
        XCTAssertEqual(HabitOrdering.nextSortOrder(among: [make("A", order: 0), make("B", order: 4)]), 5)
    }

    func test_normalize_makesOrderUniqueAndStable() {
        let all = [make("A", order: 0, day: 3), make("B", order: 0, day: 1), make("C", order: 0, day: 2)]
        HabitOrdering.normalize(all)
        XCTAssertEqual(Set(all.map(\.sortOrder)).count, 3)
        XCTAssertEqual(names(all), ["B", "C", "A"])
    }

    func test_move_flatList() {
        let all = [make("A", order: 0), make("B", order: 1), make("C", order: 2), make("D", order: 3)]
        HabitOrdering.move(all, from: IndexSet(integer: 0), to: 3, allHabits: all) // A → перед D
        XCTAssertEqual(names(all), ["B", "C", "A", "D"])
    }

    func test_move_withinGroup_doesNotTouchOtherGroups() {
        let m1 = make("M1", order: 0, time: .morning)
        let e1 = make("E1", order: 1, time: .evening)
        let m2 = make("M2", order: 2, time: .morning)
        let e2 = make("E2", order: 3, time: .evening)
        let all = [m1, e1, m2, e2]

        HabitOrdering.move([m1, m2], from: IndexSet(integer: 1), to: 0, allHabits: all) // M2 выше M1

        XCTAssertEqual(names(all), ["M2", "E1", "M1", "E2"])   // вечерние остались на своих местах
        XCTAssertEqual(e1.sortOrder, 1)
        XCTAssertEqual(e2.sortOrder, 3)
    }

    func test_move_worksEvenWhenAllSortOrdersAreEqual() {
        let a = make("A", order: 0, day: 1), b = make("B", order: 0, day: 2), c = make("C", order: 0, day: 3)
        let all = [a, b, c]
        HabitOrdering.move(all, from: IndexSet(integer: 2), to: 0, allHabits: all) // C в начало
        XCTAssertEqual(names(all), ["C", "A", "B"])
    }
}
