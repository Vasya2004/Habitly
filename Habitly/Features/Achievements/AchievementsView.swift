import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext

    @Query private var habits: [Habit]
    @Query private var profiles: [Profile]
    @Query(sort: \Achievement.unlockedAt, order: .reverse) private var achievements: [Achievement]

    @State private var cardImage: UIImage?

    private var profile: Profile? { profiles.first }
    private var levelInfo: LevelInfo { GamificationService.levelInfo(for: profile?.xp ?? 0) }
    private var unlockedByKind: [AchievementKind: Date] {
        Dictionary(achievements.map { ($0.kind, $0.unlockedAt) }, uniquingKeysWith: { first, _ in first })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if habits.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        levelHeader
                        freezeTile
                        weeklySummarySection
                        achievementsGrid
                    }
                    .padding(Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                refillFreezesIfNeeded()
                renderCard()
            }
            .onChange(of: habits) { renderCard() }
        }
    }

    private var levelHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle().fill(Theme.brandGradient)
                    Text("\(levelInfo.level)")
                        .font(Typography.roundedFont(size: 22, weight: .heavy))
                        .foregroundStyle(.white)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text(levelInfo.title)
                        .font(Typography.title2)
                        .foregroundStyle(Theme.primaryText(for: scheme))
                    Text("\(levelInfo.currentXP) XP")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText(for: scheme))
                }
                Spacer()
            }

            ProgressView(value: levelInfo.progress)
                .tint(Color(hex: "9B5CFF"))

            if let ceiling = levelInfo.ceilingXP {
                Text("Ещё \(ceiling - levelInfo.currentXP) XP до следующего уровня")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText(for: scheme))
            } else {
                Text("Максимальный уровень достигнут 🎉")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText(for: scheme))
            }
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    private var freezeTile: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle().fill(Color(hex: "3ABEEB").opacity(0.18))
                Image(systemName: "snowflake")
                    .foregroundStyle(Color(hex: "3ABEEB"))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("Заморозки стрика")
                    .font(Typography.headline)
                    .foregroundStyle(Theme.primaryText(for: scheme))
                Text("Осталось \(profile?.streakFreezesLeft ?? 0) в этом месяце")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText(for: scheme))
            }
            Spacer()
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    private var weeklySummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Итоги недели")
                .font(Typography.headline)
                .foregroundStyle(Theme.primaryText(for: scheme))

            WeeklySummaryCardView(data: WeeklySummaryData.compute(habits: habits), profileName: profile?.name ?? "")
                .frame(maxWidth: .infinity)

            if let cardImage {
                ShareLink(
                    item: Image(uiImage: cardImage),
                    preview: SharePreview("Итоги недели в Habitly", image: Image(uiImage: cardImage))
                ) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Поделиться")
                    }
                    .font(Typography.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(Theme.brandGradient, in: Capsule())
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var achievementsGrid: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Достижения")
                .font(Typography.headline)
                .foregroundStyle(Theme.primaryText(for: scheme))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.xs) {
                ForEach(AchievementKind.allCases) { kind in
                    AchievementBadgeView(kind: kind, unlockedAt: unlockedByKind[kind])
                }
            }
            .padding(Spacing.md)
            .cardStyle()
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer(minLength: 160)
            EmptyStateView(
                symbol: "trophy.fill",
                title: "Награды впереди",
                message: "Выполняйте привычки, чтобы открывать достижения и получать XP"
            )
            Spacer()
        }
    }

    private func renderCard() {
        let renderer = ImageRenderer(content:
            WeeklySummaryCardView(data: WeeklySummaryData.compute(habits: habits), profileName: profile?.name ?? "")
        )
        renderer.scale = 3
        cardImage = renderer.uiImage
    }

    private func refillFreezesIfNeeded() {
        guard let profile else { return }
        GamificationService.refillFreezesIfNeeded(profile: profile)
        try? modelContext.save()
    }
}

#Preview {
    AchievementsView()
        .modelContainer(for: [Habit.self, HabitLog.self, Profile.self, Achievement.self], inMemory: true)
}
