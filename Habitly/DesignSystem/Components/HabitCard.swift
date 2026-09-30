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
    /// Награда, всплывающая при выполнении; nil — не показывать.
    var xpReward: Int? = GamificationService.xpPerCompletion

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var checkProgress: CGFloat = 0
    @State private var burstTrigger = 0
    @State private var pulse = false
    @State private var iconPop = false
    /// Перелив цвета по карточке: прогресс 0...1 и видимость управляются отдельно, чтобы не «откатываться» назад.
    @State private var washProgress: CGFloat = 0
    @State private var washVisible = false
    /// Эффект показываем только после нажатия пользователя, а не при смене даты или перерисовке списка.
    @State private var awaitingUserCompletion = false

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
                        .foregroundStyle(Theme.primaryText(for: scheme).opacity(isCompleted ? 0.7 : 1))
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(isCompleted ? AnyShapeStyle(color.gradient) : AnyShapeStyle(Theme.secondaryText(for: scheme)))
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
        .background {
            CompletionWash(progress: washProgress, color: color)
                .opacity(washVisible ? 1 : 0)
                .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .cardStyle()
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(color.gradient.opacity(isCompleted ? 0.6 : 0), lineWidth: 1.5)
        }
        .scaleEffect(pulse ? 1.03 : 1)
        .animation(reduceMotion ? nil : Motion.spring, value: isCompleted)
        .onAppear {
            checkProgress = isCompleted ? 1 : 0
            setWash(filled: isCompleted)
        }
        .onChange(of: isCompleted) { _, done in
            if done {
                if awaitingUserCompletion {
                    celebrate()
                } else {
                    checkProgress = 1
                    setWash(filled: true)
                }
            } else {
                checkProgress = 0
                fadeOutWash()
            }
            awaitingUserCompletion = false
        }
        .accessibilityElement(children: .contain)
    }

    /// Мгновенно выставляет перелив в готовое состояние (без анимации).
    private func setWash(filled: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            washProgress = filled ? 1 : 0
            washVisible = filled
        }
    }

    /// Снятие отметки: цвет плавно гаснет на месте — без обратного движения.
    private func fadeOutWash() {
        withAnimation(.easeOut(duration: 0.35)) { washVisible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard !isCompleted else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { washProgress = 0 }
        }
    }

    /// Медленный перелив слева направо, один раз.
    private func startWash() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            washProgress = 0
            washVisible = true
        }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 1.6)) { washProgress = 1 }
        }
    }

    private func resetAwaitingFlag() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { awaitingUserCompletion = false }
    }

    /// Полный эффект выполнения по времени: сжатие кнопки → галочка → салют и волна → пульс карточки → иконка.
    private func celebrate() {
        guard !reduceMotion else {
            checkProgress = 1
            setWash(filled: true)
            return
        }
        burstTrigger += 1
        startWash()
        checkProgress = 0
        withAnimation(.easeOut(duration: 0.3).delay(0.1)) { checkProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.easeOut(duration: 0.12)) { pulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(Motion.bouncy) { pulse = false }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) { iconPop = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(Motion.bouncy) { iconPop = false }
            }
        }
        Haptics.shared.success()
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
        .overlay(alignment: .bottomTrailing) {
            if showsStepper && isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white, color.end)
                    .background(Circle().fill(.white).padding(2))
                    .offset(x: 6, y: 6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .background { IconFlash(trigger: burstTrigger, color: color) }
        .scaleEffect(iconPop ? 1.18 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(subtitle)")
    }

    private var completeButton: some View {
        Button {
            let willComplete = !isCompleted
            awaitingUserCompletion = willComplete
            resetAwaitingFlag()
            onToggle()
            if !willComplete { Haptics.shared.impact(.soft) }
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 2.5)
                    .opacity(isCompleted ? 0 : 1)

                Circle()
                    .fill(color.gradient)
                    .scaleEffect(isCompleted ? 1 : 0.4)
                    .opacity(isCompleted ? 1 : 0)
                    .shadow(color: color.start.opacity(isCompleted ? 0.5 : 0), radius: 8, y: 3)

                CheckmarkShape()
                    .trim(from: 0, to: checkProgress)
                    .stroke(.white, style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
                    .padding(6)
            }
            .frame(width: 30, height: 30)
            .completionSquash(trigger: burstTrigger)
            .background { ParticleBurst(trigger: burstTrigger, color: color).frame(width: 320, height: 200) }
            .overlay(alignment: .center) { xpFloater }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .animation(reduceMotion ? nil : Motion.bouncy, value: isCompleted)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCompleted ? Text("Выполнено") : Text("Отметить выполненным"))
        .accessibilityAddTraits(isCompleted ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private var xpFloater: some View {
        if let xpReward, !reduceMotion {
            XPFloater(trigger: burstTrigger, amount: xpReward, color: color)
        }
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
                awaitingUserCompletion = true
                resetAwaitingFlag()
                onIncrement?()
                Haptics.shared.impact(.soft)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .background { ParticleBurst(trigger: burstTrigger, color: color).frame(width: 320, height: 200) }
                    .overlay(alignment: .center) { xpFloater }
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
