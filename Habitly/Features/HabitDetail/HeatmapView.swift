import SwiftUI

/// Календарь-хитмап в стиле GitHub: недели по горизонтали, дни недели по вертикали.
struct HeatmapView: View {
    let habit: Habit
    var weeks: Int = 20

    @Environment(\.colorScheme) private var scheme
    private let calendar: Calendar = .current
    private let cellSize: CGFloat = 13
    private let cellSpacing: CGFloat = 3

    private var weekColumns: [[Date?]] {
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today) // 1 = вс
        let daysFromMonday = (weekday + 5) % 7
        guard let currentWeekMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else { return [] }
        guard let firstWeekMonday = calendar.date(byAdding: .weekOfYear, value: -(weeks - 1), to: currentWeekMonday) else { return [] }

        var columns: [[Date?]] = []
        var weekStart = firstWeekMonday
        for _ in 0..<weeks {
            var column: [Date?] = []
            for dayOffset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { column.append(nil); continue }
                column.append(day > today ? nil : day)
            }
            columns.append(column)
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { break }
            weekStart = next
        }
        return columns
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: cellSpacing) {
                ForEach(Array(weekColumns.enumerated()), id: \.offset) { _, column in
                    VStack(spacing: cellSpacing) {
                        ForEach(Array(column.enumerated()), id: \.offset) { _, day in
                            cell(for: day)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func cell(for day: Date?) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color(for: day))
            .frame(width: cellSize, height: cellSize)
    }

    private func color(for day: Date?) -> Color {
        guard let day else { return .clear }
        guard habit.schedule.isActive(on: day, calendar: calendar), day >= calendar.startOfDay(for: habit.createdAt) else {
            return Color.gray.opacity(scheme == .dark ? 0.08 : 0.06)
        }
        if habit.log(on: day, calendar: calendar)?.isFrozen == true {
            return Color(hex: "3ABEEB").opacity(0.7)
        }
        let fraction = habit.completionFraction(on: day, calendar: calendar)
        if fraction <= 0 {
            return Color.gray.opacity(scheme == .dark ? 0.16 : 0.12)
        }
        return habit.accentColor.start.opacity(0.3 + fraction * 0.7)
    }
}

#Preview {
    let habit = Habit(name: "Пить воду", icon: "💧", colorIndex: 1, type: .boolean)
    return HeatmapView(habit: habit)
        .padding()
        .background(Theme.backgroundGradient(for: .dark))
}
