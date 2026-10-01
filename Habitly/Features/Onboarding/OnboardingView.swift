import SwiftUI
import SwiftData

/// Онбординг из 4 экранов: приветствие → цели → стартовые привычки → уведомления.
struct OnboardingView: View {
    var onFinished: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]

    @State private var step: Step = .welcome
    @State private var name: String = ""
    @FocusState private var nameFocused: Bool
    @State private var selectedGoals: Set<HabitCategory> = []
    @State private var selectedTemplateIDs: Set<UUID> = []

    private enum Step: Int, CaseIterable {
        case welcome, goals, habits, notifications
    }

    private var suggestedTemplates: [HabitTemplate] {
        guard !selectedGoals.isEmpty else { return [] }
        return HabitTemplate.all.filter { selectedGoals.contains($0.category) }
    }

    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: .dark).ignoresSafeArea()

            VStack(spacing: 0) {
                progressDots
                    .padding(.top, Spacing.md)

                TabView(selection: $step) {
                    welcomeStep.tag(Step.welcome)
                    goalsStep.tag(Step.goals)
                    habitsStep.tag(Step.habits)
                    notificationsStep.tag(Step.notifications)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(Motion.spring, value: step)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { nameFocused = false }
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - Прогресс

    private var progressDots: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Step.allCases, id: \.self) { s in
                Capsule()
                    .fill(s == step ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color.white.opacity(0.2)))
                    .frame(width: s == step ? 22 : 8, height: 8)
                    .animation(Motion.tap, value: step)
            }
        }
    }

    // MARK: - Шаг 1: приветствие

    private var welcomeStep: some View {
        OnboardingScaffold(
            illustrationSymbol: "sparkles",
            title: "Добро пожаловать в Habitly",
            subtitle: "Формируйте полезные привычки маленькими шагами — красиво, спокойно и без давления.",
            buttonTitle: "Продолжить",
            buttonAction: { advance(to: .goals) }
        ) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Как вас зовут?")
                    .font(Typography.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                TextField("", text: $name, prompt: Text("Необязательно").foregroundStyle(Color.white.opacity(0.4)))
                    .textFieldStyle(.plain)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit { nameFocused = false }
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.control)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.control)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )
                    .foregroundStyle(.white)
                    .tint(.white)
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Шаг 2: цели

    private var goalsStep: some View {
        OnboardingScaffold(
            illustrationSymbol: "target",
            title: "Чего хотите добиться?",
            subtitle: "Выберите одну или несколько целей — подберём подходящие привычки.",
            buttonTitle: "Далее",
            buttonEnabled: !selectedGoals.isEmpty,
            buttonAction: { advance(to: .habits) }
        ) {
            VStack(spacing: Spacing.sm) {
                ForEach(HabitCategory.allCases) { category in
                    goalRow(category)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    private func goalRow(_ category: HabitCategory) -> some View {
        let isSelected = selectedGoals.contains(category)
        return Button {
            Haptics.shared.selectionChanged()
            withAnimation(Motion.tap) {
                if isSelected { selectedGoals.remove(category) } else { selectedGoals.insert(category) }
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: category.symbol)
                    .frame(width: 28)
                Text(category.title)
                    .font(Typography.headline)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            }
            .foregroundStyle(.white)
            .padding(Spacing.md)
            .background { OnboardingCardBackground(isSelected: isSelected) }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Шаг 3: стартовые привычки

    private var habitsStep: some View {
        OnboardingScaffold(
            illustrationSymbol: "checkmark.circle.fill",
            title: "Начнём с этого",
            subtitle: "Мы подобрали привычки под ваши цели — оставьте те, что откликаются.",
            buttonTitle: "Далее",
            buttonAction: { advance(to: .notifications) }
        ) {
            VStack(spacing: Spacing.sm) {
                ForEach(Array(suggestedTemplates.prefix(5))) { template in
                    templateRow(template)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
        .onAppear {
            if selectedTemplateIDs.isEmpty {
                selectedTemplateIDs = Set(suggestedTemplates.prefix(5).map(\.id))
            }
        }
    }

    private func templateRow(_ template: HabitTemplate) -> some View {
        let isSelected = selectedTemplateIDs.contains(template.id)
        return Button {
            Haptics.shared.selectionChanged()
            withAnimation(Motion.tap) {
                if isSelected { selectedTemplateIDs.remove(template.id) } else { selectedTemplateIDs.insert(template.id) }
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle().fill(HabitColor.palette[template.colorIndex].gradient)
                    HabitIconView(icon: template.icon, size: 24)
                }
                .frame(width: 36, height: 36)

                Text(template.name)
                    .font(Typography.headline)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(.white)
            }
            .padding(Spacing.sm)
            .background { OnboardingCardBackground(isSelected: false) }
            .opacity(isSelected ? 1 : 0.55)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Шаг 4: уведомления

    private var notificationsStep: some View {
        OnboardingScaffold(
            illustrationSymbol: "bell.badge.fill",
            title: "Не забывайте о привычках",
            subtitle: "Включите уведомления — мы дружелюбно напомним в нужное время, без спама.",
            buttonTitle: "Разрешить уведомления",
            buttonAction: {
                Task {
                    _ = await NotificationService.shared.requestAuthorization()
                    finish()
                }
            }
        ) {
            Button("Может быть позже") { finish() }
                .font(Typography.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Навигация

    private func advance(to next: Step) {
        Haptics.shared.impact(.soft)
        withAnimation(Motion.spring) { step = next }
    }

    private func finish() {
        let profile = profiles.first ?? {
            let p = Profile()
            modelContext.insert(p)
            return p
        }()
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.hasCompletedOnboarding = true

        var nextOrder = HabitOrdering.nextSortOrder(among: (try? modelContext.fetch(FetchDescriptor<Habit>())) ?? [])
        for template in suggestedTemplates where selectedTemplateIDs.contains(template.id) {
            let habit = Habit(
                name: template.name, icon: template.icon, colorIndex: template.colorIndex,
                type: template.type, goalValue: template.goalValue, unit: template.unit,
                schedule: template.schedule, timeOfDay: template.timeOfDay
            )
            habit.sortOrder = nextOrder
            nextOrder += 1
            modelContext.insert(habit)
        }

        try? modelContext.save()
        Haptics.shared.success()
        onFinished()
    }
}

/// Общий каркас шага онбординга: иллюстрация, заголовок, подзаголовок, кастомный контент и кнопка.
private struct OnboardingScaffold<Content: View>: View {
    var illustrationSymbol: String
    var title: LocalizedStringKey
    var subtitle: LocalizedStringKey
    var buttonTitle: LocalizedStringKey
    var buttonEnabled: Bool = true
    var buttonAction: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                OnboardingIllustration(symbol: illustrationSymbol)
                    .padding(.top, Spacing.sm)

                VStack(spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.title)
                        .fitsWidth(lines: 2, minScale: 0.7)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(subtitle)
                        .font(Typography.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Spacing.lg)

                content
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.md)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CapsuleButton(title: buttonTitle, action: buttonAction)
                .opacity(buttonEnabled ? 1 : 0.4)
                .disabled(!buttonEnabled)
                .padding(.vertical, Spacing.md)
        }
    }
}

/// Карточка выбора на тёмном фоне онбординга: тонкая подложка вместо серого системного материала.
private struct OnboardingCardBackground: View {
    var isSelected: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: Radius.control)
            .fill(isSelected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color.white.opacity(0.08)))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.control)
                    .stroke(Color.white.opacity(isSelected ? 0 : 0.15), lineWidth: 1)
            )
    }
}

#Preview {
    OnboardingView(onFinished: {})
        .modelContainer(for: [Habit.self, HabitLog.self, Profile.self, Achievement.self], inMemory: true)
}
