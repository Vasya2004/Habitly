import SwiftUI

/// Bento-плитка статистики произвольного размера (обычная или крупная, на всю ширину).
struct BentoTile: View {
    var symbol: String
    var value: String
    var label: String
    var isLarge: Bool = false

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(systemName: symbol)
                .font(.system(size: isLarge ? 22 : 16, weight: .semibold))
                .foregroundStyle(Theme.brandGradient)
            Text(value)
                .font(isLarge ? Typography.bigNumber : Typography.mediumNumber)
                .foregroundStyle(Theme.primaryText(for: scheme))
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Theme.secondaryText(for: scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .frame(minHeight: isLarge ? 140 : 108)
        .cardStyle(cornerRadius: Radius.control)
    }
}

#Preview {
    VStack(spacing: 12) {
        BentoTile(symbol: "percent", value: "78%", label: "Выполнено за месяц", isLarge: true)
        HStack(spacing: 12) {
            BentoTile(symbol: "calendar", value: "Вторник", label: "Продуктивный день")
            BentoTile(symbol: "sunrise.fill", value: "Утро", label: "Активное время")
        }
    }
    .padding()
    .background(Theme.backgroundGradient(for: .dark))
}
