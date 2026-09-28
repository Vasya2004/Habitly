import SwiftUI

struct RootView: View {
    @Environment(\.colorScheme) private var scheme
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
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Habit.self, HabitLog.self, Profile.self, Achievement.self], inMemory: true)
}
