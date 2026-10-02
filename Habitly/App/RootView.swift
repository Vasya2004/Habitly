import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Query private var habits: [Habit]
    @Query private var profiles: [Profile]

    @State private var selection: MainTab = .today
    @State private var visitedTabs: Set<MainTab> = [.today]
    @State private var isWarmingUp = true
    /// День, который считался «сегодняшним» при последней проверке.
    @State private var lastActiveDay = Calendar.current.startOfDay(for: .now)
    @State private var dayChange = DayChange()
    #if DEBUG
    @State private var debugDayArmed = false
    #endif
    @State private var isPresentingEditor = false

    private var profile: Profile? { profiles.first }
    private var needsOnboarding: Bool { profile?.hasCompletedOnboarding != true }

    private var preferredScheme: ColorScheme? {
        switch profile?.appearance ?? .system {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var body: some View {
        Group {
            if needsOnboarding {
                OnboardingView { }
            } else {
                mainTabs
            }
        }
        .preferredColorScheme(preferredScheme)
    }

    @ViewBuilder
    private func screen(for tab: MainTab) -> some View {
        switch tab {
        case .today: TodayView(dayChange: dayChange, onAdd: { isPresentingEditor = true })
        case .stats: StatsView()
        case .achievements: AchievementsView()
        case .settings: SettingsView()
        }
    }

    /// iOS 26+: штатный TabView — родной Liquid Glass, плавное перетекание индикатора и перетаскивание пальцем.
    @available(iOS 26.0, *)
    private var nativeTabs: some View {
        ZStack(alignment: .bottomTrailing) {
            Theme.backgroundGradient(for: scheme).ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(MainTab.allCases) { tab in
                    Tab(tab.title, systemImage: tab.symbol, value: tab) {
                        screen(for: tab)
                    }
                }
            }
            .tint(Color(hex: "7C5CFF"))

            // Заставка на время прогрева: пока она закрывает экран, вкладки по очереди создаются в фоне.
            if isWarmingUp {
                Theme.backgroundGradient(for: scheme)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .task { await warmUpTabs() }
    }

    /// Первое открытие вкладки — самое тяжёлое (создание экрана, графика, шрифтов). Делаем его один раз при запуске
    /// под заставкой, чтобы пользователь потом переключался между уже готовыми экранами без подвисаний.
    @available(iOS 26.0, *)
    private func warmUpTabs() async {
        guard isWarmingUp else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        for tab in [MainTab.stats, .achievements, .settings, .today] {
            withTransaction(transaction) { selection = tab }
            try? await Task.sleep(for: .milliseconds(140))
        }
        withAnimation(.easeOut(duration: 0.25)) { isWarmingUp = false }
    }

    /// iOS 17–25: своё меню с кнопкой «+» в центре.
    private var customTabs: some View {
        ZStack(alignment: .bottom) {
            Theme.backgroundGradient(for: scheme).ignoresSafeArea()

            // Экраны вкладок создаются при первом открытии и дальше не пересоздаются.
            ZStack {
                ForEach(MainTab.allCases) { tab in
                    if visitedTabs.contains(tab) || selection == tab {
                        screen(for: tab)
                            .opacity(selection == tab ? 1 : 0)
                            .allowsHitTesting(selection == tab)
                            .accessibilityHidden(selection != tab)
                            .zIndex(selection == tab ? 1 : 0)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selection)
            .onChange(of: selection) { _, tab in visitedTabs.insert(tab) }

            MainTabBar(selection: $selection) {
                isPresentingEditor = true
            }
            .padding(.bottom, -Spacing.xs)
        }
    }

    /// Проверяет, не наступил ли новый день. Вернулись из фона в новый день — возвращаем на «Сегодня».
    /// Новый день наступил при открытом приложении — тихо обновляем выбранную дату.
    private func handleDayChange(returningFromBackground: Bool) {
        #if DEBUG
        // Проверка вручную: с аргументом запуска -debugPretendYesterday первое открытие «взводит» вчерашнюю дату,
        // и следующее возвращение из фона ведёт себя так, будто наступил новый день.
        if ProcessInfo.processInfo.arguments.contains("-debugPretendYesterday"), !debugDayArmed {
            debugDayArmed = true
            lastActiveDay = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: .now)) ?? lastActiveDay
            return
        }
        #endif
        guard DayRollover.hasDayChanged(since: lastActiveDay) else { return }
        lastActiveDay = Calendar.current.startOfDay(for: .now)

        if returningFromBackground {
            selection = .today
            isPresentingEditor = false
        }
        dayChange = DayChange(token: dayChange.token + 1, isFullReset: returningFromBackground)
        WidgetRefreshService.reloadAll()
    }

    private var mainTabs: some View {
        Group {
            if #available(iOS 26.0, *) {
                nativeTabs
            } else {
                customTabs
            }
        }
        .sheet(isPresented: $isPresentingEditor) {
            HabitEditorView(mode: .create)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            handleDayChange(returningFromBackground: scenePhase != .active)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            handleDayChange(returningFromBackground: scenePhase != .active)
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            handleDayChange(returningFromBackground: true)
            WidgetRefreshService.applyPendingWidgetToggles()
            WidgetRefreshService.reloadAll()
            Haptics.shared.isEnabled = profile?.hapticsEnabled ?? true
            await NotificationService.shared.rescheduleAll(habits: habits)
        }
        .onOpenURL { url in
            guard url.scheme == "habitly" else { return }
            if url.host == "today" { selection = .today }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Habit.self, HabitLog.self, Profile.self, Achievement.self], inMemory: true)
}
