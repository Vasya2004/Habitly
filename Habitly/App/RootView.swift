import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Query private var habits: [Habit]
    @Query private var profiles: [Profile]

    @State private var selection: MainTab = .today
    @State private var visitedTabs: Set<MainTab> = [.today]
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
        case .today: TodayView()
        case .stats: StatsView()
        case .achievements: AchievementsView()
        case .settings: SettingsView()
        }
    }

    private var mainTabs: some View {
        ZStack(alignment: .bottom) {
            Theme.backgroundGradient(for: scheme).ignoresSafeArea()

            // Экраны вкладок создаются при первом открытии и дальше не пересоздаются: переключение
            // не перестраивает запросы к базе, а прокрутка и открытые детали сохраняются.
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
            // Ниже обычного: бар «парит» у самого нижнего края, рядом с индикатором «Домой».
            .padding(.bottom, -Spacing.xs)
        }
        .sheet(isPresented: $isPresentingEditor) {
            HabitEditorView(mode: .create)
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
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
