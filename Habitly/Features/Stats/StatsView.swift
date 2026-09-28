import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    @State private var period: StatsPeriod = .month
    @State private var animateChart = false

    private var summary: StatsSummary {
        StatsCalculator.summary(habits: habits, period: period)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if habits.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        header
                        overallTile
                        secondaryTiles
                        bestHabitsSection
                        chartSection
                        insightsSection
                    }
                    .padding(Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .scrollIndicators(.hidden)
            .navigationBarHidden(true)
            .onAppear { triggerChartAnimation() }
            .onChange(of: period) { _, _ in triggerChartAnimation() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Статистика")
                .font(Typography.largeTitle)
                .foregroundStyle(Theme.primaryText(for: scheme))

            Picker("Период", selection: $period) {
                ForEach(StatsPeriod.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var overallTile: some View {
        BentoTile(
            symbol: "percent",
            value: "\(Int((summary.overallRate * 100).rounded()))%",
            label: "Выполнено за период «\(period.rawValue.lowercased())»",
            isLarge: true
        )
    }

    private var secondaryTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
            BentoTile(
                symbol: "calendar",
                value: summary.bestWeekday.map { StatsCalculator.weekdayName($0) } ?? "—",
                label: "Продуктивный день"
            )
            BentoTile(
                symbol: summary.bestTimeOfDay?.symbol ?? "clock.fill",
                value: summary.bestTimeOfDay?.title ?? "—",
                label: "Активное время"
            )
            BentoTile(
                symbol: "checkmark.seal.fill",
                value: "\(summary.totalCompletions)",
                label: "Всего выполнений"
            )
            BentoTile(
                symbol: "sparkles",
                value: "\(habits.filter { !$0.isArchived }.count)",
                label: "Активных привычек"
            )
        }
    }

    private var bestHabitsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Лучшие привычки")
                .font(Typography.headline)
                .foregroundStyle(Theme.primaryText(for: scheme))

            if summary.bestHabits.isEmpty {
                Text("Пока недостаточно данных")
                    .font(Typography.subheadline)
                    .foregroundStyle(Theme.secondaryText(for: scheme))
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(summary.bestHabits) { entry in
                        bestHabitRow(entry)
                    }
                }
                .padding(Spacing.md)
                .cardStyle()
            }
        }
    }

    private func bestHabitRow(_ entry: HabitRateEntry) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle().fill(entry.habit.accentColor.gradient)
                HabitIconView(icon: entry.habit.icon, size: 26)
            }
            .frame(width: 32, height: 32)

            Text(entry.habit.name)
                .font(Typography.subheadline)
                .foregroundStyle(Theme.primaryText(for: scheme))
                .lineLimit(1)

            Spacer()

            Text("\(Int((entry.rate * 100).rounded()))%")
                .font(Typography.subheadline.weight(.semibold))
                .foregroundStyle(entry.habit.accentColor.gradient)
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Динамика выполнения")
                .font(Typography.headline)
                .foregroundStyle(Theme.primaryText(for: scheme))

            Chart(summary.chartPoints) { point in
                AreaMark(
                    x: .value("Дата", point.date, unit: summary.isMonthlyBucketed ? .month : .day),
                    y: .value("%", animateChart ? point.rate : 0)
                )
                .foregroundStyle(Theme.brandGradient.opacity(0.3))
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Дата", point.date, unit: summary.isMonthlyBucketed ? .month : .day),
                    y: .value("%", animateChart ? point.rate : 0)
                )
                .foregroundStyle(Theme.brandGradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            .frame(height: 170)
            .chartYScale(domain: 0...1)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 0.5, 1]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let d = value.as(Double.self) { Text("\(Int(d * 100))%") }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.9), value: animateChart)
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Инсайты")
                .font(Typography.headline)
                .foregroundStyle(Theme.primaryText(for: scheme))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(Array(insights.enumerated()), id: \.offset) { _, insight in
                    HStack(alignment: .top, spacing: Spacing.xs) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Theme.brandGradient)
                            .font(.system(size: 13))
                            .padding(.top, 2)
                        Text(insight)
                            .font(Typography.subheadline)
                            .foregroundStyle(Theme.primaryText(for: scheme))
                    }
                }
            }
            .padding(Spacing.md)
            .cardStyle()
        }
    }

    private var insights: [String] {
        var result: [String] = []
        if let weekday = summary.bestWeekday, summary.bestWeekdayCount > 0 {
            result.append("Вы чаще всего выполняете привычки по \(StatsCalculator.weekdayName(weekday).lowercased())ам")
        }
        if let time = summary.bestTimeOfDay, summary.bestTimeOfDayCount > 0 {
            result.append("Больше всего привычек вы выполняете в это время дня: «\(time.title.lowercased())»")
        }
        if let best = summary.bestHabits.first {
            result.append("Лучшая привычка периода — «\(best.habit.name)» с результатом \(Int((best.rate * 100).rounded()))%")
        }
        if result.isEmpty {
            result.append("Отмечайте привычки регулярно, чтобы здесь появились персональные инсайты")
        }
        return result
    }

    private var emptyState: some View {
        VStack {
            Spacer(minLength: 120)
            EmptyStateView(
                symbol: "chart.bar.fill",
                title: "Статистика появится здесь",
                message: "Как только вы начнёте отмечать привычки, тут появятся графики и инсайты"
            )
            Spacer()
        }
    }

    private func triggerChartAnimation() {
        animateChart = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animateChart = true
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [Habit.self, HabitLog.self, Profile.self, Achievement.self], inMemory: true)
}
