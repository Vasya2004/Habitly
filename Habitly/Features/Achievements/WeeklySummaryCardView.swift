import SwiftUI

struct WeeklySummaryData {
    let activeDays: Int
    let totalCompletions: Int
    let bestStreak: Int
    let xpEarned: Int
    let weekRangeText: String

    static func compute(habits: [Habit], asOf: Date = .now, calendar: Calendar = .current) -> WeeklySummaryData {
        let today = calendar.startOfDay(for: asOf)
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today) else {
            return WeeklySummaryData(activeDays: 0, totalCompletions: 0, bestStreak: 0, xpEarned: 0, weekRangeText: "")
        }

        var activeDaySet: Set<Date> = []
        var totalCompletions = 0
        var xpEarned = 0

        for habit in habits {
            for log in habit.logs where log.date >= weekStart && log.date <= today {
                guard habit.isLogCompleted(log) else { continue }
                totalCompletions += 1
                activeDaySet.insert(log.date)
                if log.xpAwarded { xpEarned += GamificationService.xpPerCompletion }
            }
        }

        let bestStreak = habits.map { $0.streakStatsWithFreezes(asOf: asOf, calendar: calendar).currentStreak }.max() ?? 0

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        let rangeText = "\(formatter.string(from: weekStart)) – \(formatter.string(from: today))"

        return WeeklySummaryData(
            activeDays: activeDaySet.count,
            totalCompletions: totalCompletions,
            bestStreak: bestStreak,
            xpEarned: xpEarned,
            weekRangeText: rangeText
        )
    }
}

/// Карточка недельного итога — рендерится в изображение для шеринга.
struct WeeklySummaryCardView: View {
    let data: WeeklySummaryData
    let profileName: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Итоги недели")
                        .font(Typography.title2)
                        .foregroundStyle(.white)
                    Text(data.weekRangeText)
                        .font(Typography.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 26))
                    .foregroundStyle(.white.opacity(0.85))
            }

            HStack(spacing: Spacing.md) {
                metric(value: "\(data.activeDays)/7", label: "Активных дней")
                metric(value: "\(data.totalCompletions)", label: "Выполнений")
            }
            HStack(spacing: Spacing.md) {
                metric(value: "\(data.bestStreak)", label: "Лучший стрик")
                metric(value: "+\(data.xpEarned)", label: "XP заработано")
            }

            Spacer(minLength: 0)

            HStack {
                Image(systemName: "app.badge.checkmark.fill")
                Text(profileName.isEmpty ? "Habitly" : profileName)
                Spacer()
                Text("Habitly")
                    .font(Typography.caption.weight(.bold))
            }
            .font(Typography.caption)
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding(Spacing.lg)
        .frame(width: 340, height: 380)
        .background(Theme.brandGradient)
        .clipShape(RoundedRectangle(cornerRadius: Radius.cardLarge, style: .continuous))
    }

    private func metric(value: String, label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Typography.roundedFont(size: 30, weight: .heavy))
                .foregroundStyle(.white)
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    WeeklySummaryCardView(
        data: WeeklySummaryData(activeDays: 5, totalCompletions: 18, bestStreak: 6, xpEarned: 180, weekRangeText: "22 сен – 28 сен"),
        profileName: "Вася"
    )
    .padding()
    .background(Theme.backgroundGradient(for: .dark))
}
