import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Настройки")
                    .font(Typography.largeTitle)
                    .foregroundStyle(Theme.primaryText(for: scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)

                #if DEBUG
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Отладка")
                        .font(Typography.subheadline)
                        .foregroundStyle(Theme.secondaryText(for: scheme))
                    CapsuleButton(title: "Добавить тестовые привычки", systemImage: "sparkles", isProminent: false) {
                        SampleDataSeeder.seed(into: modelContext)
                    }
                }
                #endif
            }
            .padding(Spacing.md)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, HabitLog.self, Profile.self, Achievement.self], inMemory: true)
}
