import SwiftUI

/// Карточка привычки для списка на экране "Сегодня".
struct HabitCard: View {
    var icon: String
    var title: String
    var subtitle: String
    var color: HabitColor
    var streak: Int
    var progress: Double
    var isCompleted: Bool
    var showsStepper: Bool
    var onIncrement: (() -> Void)?
    var onDecrement: (() -> Void)?
    var onToggle: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var didBounce = false

    var body: some View {
        // При крупном шрифте кнопки уходят под текст, иначе название режется посреди слова.
        let isLarge = typeSize.isAccessibilitySize
        let layout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm))
            : AnyLayout(HStackLayout(spacing: Spacing.sm))

        return layout {
            HStack(spacing: Spacing.sm) {
                iconBadge

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.headline)
                        .foregroundStyle(Theme.primaryText(for: scheme))
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText(for: scheme))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: Spacing.sm) {
                if isLarge { Spacer(minLength: 0) }

                if streak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 12))
                        Text("\(streak)")
                            .font(Typography.subheadline)
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(Theme.secondaryText(for: scheme))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Стрик \(streak) дней")
                }

                if showsStepper {
                    stepper
                } else {
                    completeButton
                }
            }
        }
        .padding(Spacing.sm)
        .cardStyle()
        .accessibilityElement(children: .contain)
    }

    private var iconBadge: some View {
        ZStack {
            Circle().fill(color.gradient)
            HabitIconView(icon: icon, size: 40)
        }
        .frame(width: 44, height: 44)
        .overlay(
            ProgressRing(progress: progress, gradient: color.gradient, lineWidth: 3)
                .padding(-4)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(subtitle)")
    }

    private var completeButton: some View {
        Button {
            didBounce = true
            onToggle()
            Haptics.shared.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { didBounce = false }
        } label: {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 28))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .foregroundStyle(isCompleted ? AnyShapeStyle(color.gradient) : AnyShapeStyle(Color.gray.opacity(0.3)))
                .scaleEffect(didBounce && !reduceMotion ? 1.25 : 1)
                .animation(reduceMotion ? nil : Motion.bouncy, value: didBounce)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCompleted ? Text("Выполнено") : Text("Отметить выполненным"))
        .accessibilityAddTraits(isCompleted ? [.isButton, .isSelected] : .isButton)
    }

    private var stepper: some View {
        HStack(spacing: 0) {
            Button {
                onDecrement?()
                Haptics.shared.selectionChanged()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Уменьшить: \(title)")

            Button {
                onIncrement?()
                Haptics.shared.impact(.soft)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Увеличить: \(title)")
        }
        .font(.system(size: 22))
        .foregroundStyle(color.gradient)
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        HabitCard(
            icon: "💧", title: "Пить воду", subtitle: "2 из 8 стаканов",
            color: HabitColor.palette[1], streak: 12, progress: 0.25,
            isCompleted: false, showsStepper: true,
            onIncrement: {}, onDecrement: {}, onToggle: {}
        )
        HabitCard(
            icon: "📖", title: "Читать", subtitle: "Выполнено",
            color: HabitColor.palette[2], streak: 5, progress: 1,
            isCompleted: true, showsStepper: false,
            onToggle: {}
        )
    }
    .padding()
    .background(Theme.backgroundGradient(for: .dark))
}
