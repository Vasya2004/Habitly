import SwiftUI

/// Горизонтальная лента дней текущей недели с выделением сегодняшнего/выбранного дня.
struct WeekStrip: View {
    @Binding var selectedDate: Date
    var weekStartsMonday: Bool = true

    @Environment(\.colorScheme) private var scheme
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = weekStartsMonday ? 2 : 1
        return cal
    }

    private var days: [Date] {
        let today = calendar.startOfDay(for: .now)
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: today) else { return [today] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EE")
        return formatter
    }()

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(days, id: \.self) { day in
                dayCell(day)
            }
        }
        // Семь колонок в ряд: крупнее этого размера цифры перестают помещаться.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func dayCell(_ day: Date) -> some View {
        let today = calendar.startOfDay(for: .now)
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDate(day, inSameDayAs: today)
        let isFuture = day > today

        return Button {
            guard !isFuture else { return }
            Haptics.shared.selectionChanged()
            withAnimation(Motion.tap) { selectedDate = day }
        } label: {
            VStack(spacing: 4) {
                Text(weekdayFormatter.string(from: day).uppercased())
                    .font(Typography.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(isSelected ? .white : Theme.secondaryText(for: scheme))
                Text("\(calendar.component(.day, from: day))")
                    .font(Typography.roundedFont(size: 16, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(isSelected ? .white : Theme.primaryText(for: scheme).opacity(isFuture ? 0.3 : 1))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                        .fill(Theme.brandGradient)
                } else if isToday {
                    RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                        .strokeBorder(Theme.brandGradient, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    WeekStrip(selectedDate: .constant(.now))
        .padding()
        .background(Theme.backgroundGradient(for: .dark))
}
