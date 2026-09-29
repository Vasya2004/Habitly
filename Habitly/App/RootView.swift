import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Query private var habits: [Habit]
    @Query private var profiles: [Profile]

    @State private var selection: MainTab = .today
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

    private var mainTabs: some View {
        ZStack(alignment: .bottom) {
            Theme.backgroundGradient(for: scheme).ignoresSafeArea()

            Group {
                switch selection {
                case .today: TodayView()
                case .stats: StatsView()
                case .achievements: AchievementsView()
                case .settings: SettingsView()
                }
            }

            MainTabBar(selection: $selection) {
                isPresentingEditor = true
            }
            .padding(.bottom, Spacing.xs)
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
