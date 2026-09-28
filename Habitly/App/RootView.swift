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
            HabitEditorPlaceholder()
        }
    }
}

/// Временная заглушка листа создания привычки — полноценный редактор появится на этапе 4.
private struct HabitEditorPlaceholder: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                EmptyStateView(
                    symbol: "wand.and.stars",
                    title: "Редактор привычки",
                    message: "Появится на следующем этапе разработки"
                )
                #if DEBUG
                CapsuleButton(title: "Добавить тестовые привычки", systemImage: "sparkles", isProminent: false) {
                    SampleDataSeeder.seed(into: modelContext)
                    dismiss()
                }
                #endif
            }
            .navigationTitle("Новая привычка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    RootView()
}
