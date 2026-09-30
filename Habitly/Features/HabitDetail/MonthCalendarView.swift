import SwiftUI

/// Месячный календарь с отметками выполнения. Тап по прошлому/сегодняшнему дню
/// открывает редактирование записи за этот день.
struct MonthCalendarView: View {
    let habit: Habit
    var onSelectDay: (Date) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var visibleMonth: Date = Calendar.current.startOfDay(for: .now)

    private let calendar: Calendar = .current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = Calendar.current.mondayFirstVeryShortWeekdaySymbols

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        return formatter.string(from: visibleMonth).capitalized
    }

    private var days: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: visibleMonth) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingBlanks = (firstWeekday + 5) % 7
        let dayCount = calendar.range(of: .day, in: .month, for: visibleMonth)?.count ?? 30

        var result: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in 0..<dayCount {
            if let date = calendar.date(byAdding: .day, value: day, to: monthInterval.start) {
                result.append(date)
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Button { changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthTitle)
                    .font(Typography.headline)
                    .foregroundStyle(Theme.primaryText(for: scheme))
                Spacer()
                Button { changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(calendar.isDate(visibleMonth, equalTo: .now, toGranularity: .month))
            }
            .foregroundStyle(Theme.brandGradient)
            .buttonStyle(.plain)

            HStack {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText(for: scheme))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    dayCell(day)
                }
            }
        }
    }

    private func dayCell(_ day: Date?) -> some View {
        Group {
            if let day {
                let today = calendar.startOfDay(for: .now)
                let isFuture = day > today
                let isToday = calendar.isDate(day, inSameDayAs: today)
                let isCompleted = habit.isCompleted(on: day, calendar: calendar)
                let isFrozen = habit.log(on: day, calendar: calendar)?.isFrozen == true
                let isScheduled = habit.schedule.isActive(on: day, calendar: calendar) && day >= calendar.startOfDay(for: habit.createdAt)
                let fillStyle: AnyShapeStyle = {
                    if isFrozen { return AnyShapeStyle(Color(hex: "3ABEEB")) }
                    if isCompleted { return AnyShapeStyle(habit.accentColor.gradient) }
                    return AnyShapeStyle(Color.gray.opacity(isScheduled ? 0.15 : 0.05))
                }()

                Button {
                    guard !isFuture else { return }
                    Haptics.shared.selectionChanged()
                    onSelectDay(day)
                } label: {
                    ZStack {
                        Circle().fill(fillStyle)
                        if isToday {
                            Circle().strokeBorder(Theme.brandGradient, lineWidth: 1.5)
                        }
                        if isFrozen {
                            Image(systemName: "snowflake")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(calendar.component(.day, from: day))")
                                .font(Typography.caption)
                                .foregroundStyle(isCompleted ? .white : Theme.primaryText(for: scheme).opacity(isFuture ? 0.25 : 1))
                        }
                    }
                    .frame(height: 34)
                }
                .buttonStyle(.plain)
                .disabled(isFuture)
                .accessibilityLabel(dayAccessibilityLabel(day, isCompleted: isCompleted, isFrozen: isFrozen))
            } else {
                Color.clear.frame(height: 34)
            }
        }
    }

    private func dayAccessibilityLabel(_ day: Date, isCompleted: Bool, isFrozen: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        let dateText = formatter.string(from: day)
        if isFrozen { return String(localized: "\(dateText), защищено заморозкой") }
        return isCompleted
            ? String(localized: "\(dateText), выполнено")
            : String(localized: "\(dateText), не выполнено")
    }

    private func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: visibleMonth) else { return }
        withAnimation(Motion.spring) { visibleMonth = newMonth }
    }
}

#Preview {
    let habit = Habit(name: "Пить воду", icon: "💧", colorIndex: 1, type: .boolean)
    return MonthCalendarView(habit: habit, onSelectDay: { _ in })
        .padding()
        .background(Theme.backgroundGradient(for: .dark))
}
