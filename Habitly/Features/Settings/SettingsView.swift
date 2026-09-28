import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]

    @State private var isAuthorized = false
    @State private var didCheckAuthorization = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Настройки")
                    .font(Typography.largeTitle)
                    .foregroundStyle(Theme.primaryText(for: scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)

                notificationsSection

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
        .task { await refreshAuthorizationStatus() }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Уведомления")
                .font(Typography.subheadline)
                .foregroundStyle(Theme.secondaryText(for: scheme))

            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle().fill(Theme.brandGradient.opacity(0.18))
                    Image(systemName: isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                        .foregroundStyle(Theme.brandGradient)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isAuthorized ? "Напоминания включены" : "Напоминания выключены")
                        .font(Typography.headline)
                        .foregroundStyle(Theme.primaryText(for: scheme))
                    Text(isAuthorized
                         ? "Привычки с напоминаниями будут присылать уведомления по расписанию"
                         : "Разрешите уведомления, чтобы не забывать о привычках")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText(for: scheme))
                }
                Spacer()
            }
            .padding(Spacing.md)
            .cardStyle()

            if !isAuthorized && didCheckAuthorization {
                CapsuleButton(title: "Включить уведомления", systemImage: "bell.fill") {
                    Task {
                        _ = await NotificationService.shared.requestAuthorization()
                        await refreshAuthorizationStatus()
                        await NotificationService.shared.rescheduleAll(habits: habits)
                    }
                }
            }
        }
    }

    private func refreshAuthorizationStatus() async {
        isAuthorized = await NotificationService.shared.isAuthorized
        didCheckAuthorization = true
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, HabitLog.self, Profile.self, Achievement.self], inMemory: true)
}
