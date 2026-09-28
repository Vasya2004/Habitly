import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Query private var habits: [Habit]

    @State private var selection: MainTab = .today
    @State private var isPresentingEditor = false

    var body: some View {
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
            await NotificationService.shared.rescheduleAll(habits: habits)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Habit.self, HabitLog.self, Profile.self, Achievement.self], inMemory: true)
}
