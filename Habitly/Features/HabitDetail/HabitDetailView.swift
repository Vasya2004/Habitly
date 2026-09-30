import SwiftUI
import SwiftData
import Charts

struct HabitDetailView: View {
    let habit: Habit

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    @State private var ratePeriod: RatePeriod = .month
    @State private var selectedDay: IdentifiableDate?
    @State private var isPresentingEditor = false
    @State private var habitPendingDeletion = false

    private let calendar: Calendar = .current

    private enum RatePeriod: String, CaseIterable, Identifiable {
        case week, month, allTime
        var id: String { rawValue }

        var title: String {
            switch self {
            case .week: return String(localized: "Неделя")
            case .month: return String(localized: "Месяц")
            case .allTime: return String(localized: "Всё время")
            }
        }
    }

    private struct IdentifiableDate: Identifiable {
        let date: Date
        var id: TimeInterval { date.timeIntervalSinceReferenceDate }
    }

    private var stats: StreakStats { habit.streakStatsWithFreezes() }

    private var periodRate: Double {
        let today = calendar.startOfDay(for: .now)
        switch ratePeriod {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
            return habit.completionRate(from: start, to: today, calendar: calendar)
        case .month:
            let start = calendar.date(byAdding: .day, value: -29, to: today) ?? today
            return habit.completionRate(from: start, to: today, calendar: calendar)
        case .allTime:
            return habit.completionRate(from: habit.createdAt, to: today, calendar: calendar)
        }
    }

    private var chartData: [DailyPoint] {
        let today = calendar.startOfDay(for: .now)
        return (0..<30).reversed().compactMap { offset -> DailyPoint? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DailyPoint(date: day, fraction: habit.completionFraction(on: day, calendar: calendar))
        }
    }

    private struct DailyPoint: Identifiable {
        let date: Date
        let fraction: Double
        var id: Date { date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header

                sectionCard(title: "Хитмап") {
                    HeatmapView(habit: habit)
                }

                sectionCard(title: "Календарь") {
                    MonthCalendarView(habit: habit) { day in
                        selectedDay = IdentifiableDate(date: day)
                    }
                }

                statsSection

                sectionCard(title: "Динамика за 30 дней") {
                    chart
                }

                if !habit.note.isEmpty {
                    sectionCard(title: "Зачем эта привычка") {
                        Text(habit.note)
                            .font(Typography.body)
                            .foregroundStyle(Theme.primaryText(for: scheme))
                    }
                }
            }
            .padding(Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { isPresentingEditor = true } label: { Label("Изменить", systemImage: "pencil") }
                    Button(role: .destructive) { habitPendingDeletion = true } label: { Label("Удалить", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isPresentingEditor) {
            HabitEditorView(mode: .edit(habit))
        }
        .sheet(item: $selectedDay) { day in
            DayLogEditorView(habit: habit, date: day.date)
        }
        .alert("Удалить привычку?", isPresented: $habitPendingDeletion) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                Task { await NotificationService.shared.cancelNotifications(for: habit) }
                modelContext.delete(habit)
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("Вся история выполнения будет удалена без возможности восстановления.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle().fill(.white.opacity(0.2))
                    HabitIconView(icon: habit.icon, size: 40)
                }
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(Typography.title)
                        .fitsWidth(lines: 2, minScale: 0.7)
                        .foregroundStyle(.white)
                    Text(habit.timeOfDay.title)
                        .font(Typography.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
            }

            HStack(spacing: Spacing.md) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                    Text("\(stats.currentStreak) дней подряд")
                }
                .font(Typography.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(habit.accentColor.gradient, in: RoundedRectangle(cornerRadius: Radius.cardLarge, style: .continuous))
    }

    private func sectionCard<Content: View>(title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(Typography.headline)
                .foregroundStyle(Theme.primaryText(for: scheme))
            content()
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Статистика")
                    .font(Typography.headline)
                    .foregroundStyle(Theme.primaryText(for: scheme))
                Spacer()
                Picker("Период", selection: $ratePeriod) {
                    ForEach(RatePeriod.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(habit.accentColor.start)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                StatTileView(symbol: "flame.fill", value: "\(stats.currentStreak)", label: "Текущий стрик", tint: habit.accentColor.gradient)
                StatTileView(symbol: "trophy.fill", value: "\(stats.bestStreak)", label: "Лучший стрик", tint: habit.accentColor.gradient)
                StatTileView(symbol: "percent", value: "\(Int((periodRate * 100).rounded()))%", label: "Выполнено (\(ratePeriod.title.lowercased()))", tint: habit.accentColor.gradient)
                StatTileView(symbol: "checkmark.seal.fill", value: "\(stats.totalCompletions)", label: "Всего выполнений", tint: habit.accentColor.gradient)
            }
        }
    }

    @ViewBuilder
    private var chart: some View {
        Chart(chartData) { point in
            BarMark(
                x: .value("Дата", point.date, unit: .day),
                y: .value("Выполнение", point.fraction)
            )
            .foregroundStyle(habit.accentColor.gradient)
            .cornerRadius(3)
        }
        .frame(height: 160)
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 0.5, 1]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text("\(Int(d * 100))%")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
    }
}

#Preview {
    let habit = Habit(name: "Пить воду", icon: "💧", colorIndex: 1, type: .count, goalValue: 8, unit: "стаканов")
    return NavigationStack {
        HabitDetailView(habit: habit)
    }
    .modelContainer(for: [Habit.self, HabitLog.self, Profile.self, Achievement.self], inMemory: true)
}
