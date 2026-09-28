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
    @State private var didBounce = false

    var body: some View {
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

            Spacer(minLength: Spacing.xs)

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
            }

            if showsStepper {
                stepper
            } else {
                completeButton
            }
        }
        .padding(Spacing.sm)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityAddTraits(isCompleted ? [.isSelected] : [])
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
                .foregroundStyle(isCompleted ? AnyShapeStyle(color.gradient) : AnyShapeStyle(Color.gray.opacity(0.3)))
                .scaleEffect(didBounce && !reduceMotion ? 1.25 : 1)
                .animation(reduceMotion ? nil : Motion.bouncy, value: didBounce)
        }
        .buttonStyle(.plain)
    }

    private var stepper: some View {
        HStack(spacing: Spacing.xs) {
            Button {
                onDecrement?()
                Haptics.shared.selectionChanged()
            } label: {
                Image(systemName: "minus.circle.fill")
            }
            Button {
                onIncrement?()
                Haptics.shared.impact(.soft)
            } label: {
                Image(systemName: "plus.circle.fill")
            }
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
