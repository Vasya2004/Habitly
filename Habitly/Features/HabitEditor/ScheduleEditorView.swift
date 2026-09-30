import SwiftUI

/// Выбор частоты выполнения привычки: каждый день / конкретные дни недели / X раз в неделю.
struct ScheduleEditorView: View {
    @Binding var scheduleType: ScheduleType
    @Binding var weekdays: Set<Int>
    @Binding var timesPerWeek: Int

    @Environment(\.colorScheme) private var scheme
    private let weekdaySymbols = Calendar.current.mondayFirstVeryShortWeekdaySymbols // начиная с понедельника
    private let weekdayOrder = [2, 3, 4, 5, 6, 7, 1] // Calendar.weekday: 1=вс...7=сб

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Picker("Частота", selection: $scheduleType) {
                ForEach(ScheduleType.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

            switch scheduleType {
            case .everyDay:
                EmptyView()
            case .daysOfWeek:
                weekdayGrid
            case .timesPerWeek:
                timesStepper
            }
        }
    }

    private var weekdayGrid: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Array(zip(weekdayOrder, weekdaySymbols)), id: \.0) { weekday, symbol in
                let isOn = weekdays.contains(weekday)
                Button {
                    Haptics.shared.selectionChanged()
                    if isOn { weekdays.remove(weekday) } else { weekdays.insert(weekday) }
                } label: {
                    Text(symbol)
                        .font(Typography.subheadline)
                        .frame(width: 36, height: 36)
                        .foregroundStyle(isOn ? .white : Theme.secondaryText(for: scheme))
                        .background {
                            Circle().fill(isOn ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color.gray.opacity(0.12)))
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Calendar.current.weekdaySymbols[weekday - 1])
                .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    private var timesStepper: some View {
        HStack {
            Text("\(timesPerWeek) раз в неделю")
                .font(Typography.body)
                .foregroundStyle(Theme.primaryText(for: scheme))
            Spacer()
            Stepper("", value: $timesPerWeek, in: 1...7)
                .labelsHidden()
        }
    }
}

#Preview {
    ScheduleEditorView(scheduleType: .constant(.daysOfWeek), weekdays: .constant([2, 4, 6]), timesPerWeek: .constant(3))
        .padding()
        .background(Theme.backgroundGradient(for: .dark))
}
