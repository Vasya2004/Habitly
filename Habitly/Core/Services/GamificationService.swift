import Foundation
import SwiftData

struct LevelInfo {
    let level: Int
    let title: String
    let floorXP: Int
    let ceilingXP: Int?
    let currentXP: Int

    var progress: Double {
        guard let ceilingXP else { return 1 }
        let span = Double(ceilingXP - floorXP)
        guard span > 0 else { return 1 }
        return min(max(Double(currentXP - floorXP) / span, 0), 1)
    }
}

enum GamificationService {
    static let xpPerCompletion = 10
    static let monthlyFreezeAllowance = 2

    /// Пороги XP и названия уровней.
    private static let levels: [(threshold: Int, title: String)] = [
        (0, String(localized: "Новичок")),
        (100, String(localized: "Ученик")),
        (250, String(localized: "Практик")),
        (450, String(localized: "Настойчивый")),
        (700, String(localized: "Уверенный")),
        (1000, String(localized: "Мастер привычек")),
        (1400, String(localized: "Эксперт")),
        (1900, String(localized: "Чемпион")),
        (2500, String(localized: "Легенда")),
        (3200, String(localized: "Гуру дисциплины"))
    ]

    static func levelInfo(for xp: Int) -> LevelInfo {
        var currentIndex = 0
        for (index, entry) in levels.enumerated() where xp >= entry.threshold {
            currentIndex = index
        }
        let floor = levels[currentIndex]
        let ceiling = levels.indices.contains(currentIndex + 1) ? levels[currentIndex + 1] : nil
        return LevelInfo(
            level: currentIndex + 1,
            title: floor.title,
            floorXP: floor.threshold,
            ceilingXP: ceiling?.threshold,
            currentXP: xp
        )
    }

    /// Начисляет или списывает XP за смену статуса выполнения лога, защищаясь от повторов
    /// повторными тапами (xpAwarded). Обновляет уровень профиля.
    static func applyCompletion(isCompleted: Bool, to log: HabitLog, profile: Profile) {
        if isCompleted, !log.xpAwarded {
            profile.xp += xpPerCompletion
            log.xpAwarded = true
            log.completedAt = .now
        } else if !isCompleted, log.xpAwarded {
            profile.xp = max(0, profile.xp - xpPerCompletion)
            log.xpAwarded = false
        }
        profile.level = levelInfo(for: profile.xp).level
    }

    /// Выдаёт заморозки стрика раз в календарный месяц (до monthlyFreezeAllowance).
    static func refillFreezesIfNeeded(profile: Profile, asOf: Date = .now, calendar: Calendar = .current) {
        let monthStart = calendar.dateInterval(of: .month, for: asOf)?.start ?? asOf
        if let last = profile.lastFreezeRefillMonth, calendar.isDate(last, equalTo: monthStart, toGranularity: .month) {
            return
        }
        profile.streakFreezesLeft = monthlyFreezeAllowance
        profile.lastFreezeRefillMonth = monthStart
    }

    // MARK: - Достижения

    static func checkAchievements(
        profile: Profile,
        habits: [Habit],
        unlockedKinds: Set<AchievementKind>,
        asOf: Date = .now,
        calendar: Calendar = .current
    ) -> [AchievementKind] {
        var newlyUnlocked: [AchievementKind] = []
        func unlock(_ kind: AchievementKind, if condition: @autoclosure () -> Bool) {
            guard !unlockedKinds.contains(kind), condition() else { return }
            newlyUnlocked.append(kind)
        }

        let allLogs = habits.flatMap(\.logs)
        let totalCompletions = habits.reduce(0) { partial, habit in
            partial + habit.logs.filter { habit.isLogCompleted($0) }.count
        }
        let bestStreakOverall = habits.map { $0.streakStatsWithFreezes(asOf: asOf, calendar: calendar).bestStreak }.max() ?? 0

        unlock(.completions100, if: totalCompletions >= 100)
        unlock(.streak30, if: bestStreakOverall >= 30)
        unlock(.streak100, if: bestStreakOverall >= 100)
        unlock(.levelFive, if: levelInfo(for: profile.xp).level >= 5)

        let earlyCount = allLogs.filter { log in
            guard let habit = log.habit, habit.isLogCompleted(log) else { return false }
            return calendar.component(.hour, from: log.completedAt) < 8
        }.count
        unlock(.earlyBird, if: earlyCount >= 10)

        let nightCount = allLogs.filter { log in
            guard let habit = log.habit, habit.isLogCompleted(log) else { return false }
            return calendar.component(.hour, from: log.completedAt) >= 22
        }.count
        unlock(.nightOwl, if: nightCount >= 10)

        let daysSinceCreated = calendar.dateComponents([.day], from: calendar.startOfDay(for: profile.createdAt), to: calendar.startOfDay(for: asOf)).day ?? 0
        let activeDays = Set(allLogs.filter { log in log.habit?.isLogCompleted(log) ?? false }.map { calendar.startOfDay(for: $0.date) })
        unlock(.firstWeek, if: daysSinceCreated >= 6 && activeDays.count >= 7)

        let activeHabits = habits.filter { !$0.isArchived && !$0.isPaused }
        if !activeHabits.isEmpty {
            var perfectDays = 0
            for offset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: asOf)) else { continue }
                let scheduled = activeHabits.filter { $0.schedule.isActive(on: day, calendar: calendar) && day >= calendar.startOfDay(for: $0.createdAt) }
                guard !scheduled.isEmpty else { continue }
                if scheduled.allSatisfy({ $0.isCompleted(on: day, calendar: calendar) }) { perfectDays += 1 }
            }
            unlock(.perfectWeek, if: perfectDays >= 7)
        }

        return newlyUnlocked
    }
}
