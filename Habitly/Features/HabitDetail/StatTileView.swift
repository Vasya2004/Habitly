import SwiftUI

/// Одна плитка bento-статистики: значение + подпись.
struct StatTileView: View {
    var symbol: String
    var value: String
    var label: String
    var tint: LinearGradient

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(Typography.mediumNumber)
                .foregroundStyle(Theme.primaryText(for: scheme))
                .contentTransition(.numericText())
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Theme.secondaryText(for: scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .cardStyle(cornerRadius: Radius.control)
    }
}
