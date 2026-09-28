import SwiftUI

/// Бейдж достижения в сетке: цветной и подписанный датой, если получен; серый — если нет.
struct AchievementBadgeView: View {
    let kind: AchievementKind
    let unlockedAt: Date?

    @Environment(\.colorScheme) private var scheme

    private var isUnlocked: Bool { unlockedAt != nil }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color.gray.opacity(0.15)))
                    .frame(width: 56, height: 56)
                Image(systemName: kind.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isUnlocked ? .white : Theme.secondaryText(for: scheme))
            }

            Text(kind.title)
                .font(Typography.caption.weight(.semibold))
                .foregroundStyle(isUnlocked ? Theme.primaryText(for: scheme) : Theme.secondaryText(for: scheme))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if let unlockedAt {
                Text(unlockedAt, format: .dateTime.day().month(.abbreviated))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.secondaryText(for: scheme))
            } else {
                Text("Заблокировано")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.secondaryText(for: scheme).opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .opacity(isUnlocked ? 1 : 0.55)
    }
}

#Preview {
    HStack {
        AchievementBadgeView(kind: .firstWeek, unlockedAt: .now)
        AchievementBadgeView(kind: .streak100, unlockedAt: nil)
    }
    .padding()
    .background(Theme.backgroundGradient(for: .dark))
}
