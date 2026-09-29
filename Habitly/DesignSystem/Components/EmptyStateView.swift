import SwiftUI

/// Переиспользуемый empty state: иконка, заголовок, подпись и опциональная кнопка действия.
struct EmptyStateView: View {
    var symbol: String
    var title: LocalizedStringKey
    var message: LocalizedStringKey
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle().fill(Theme.brandGradient.opacity(0.15)).frame(width: 88, height: 88)
                Image(systemName: symbol)
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.brandGradient)
            }
            Text(title)
                .font(Typography.title2)
                .foregroundStyle(Theme.primaryText(for: scheme))
            Text(message)
                .font(Typography.body)
                .foregroundStyle(Theme.secondaryText(for: scheme))
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                CapsuleButton(title: actionTitle, systemImage: "plus", action: action)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(
        symbol: "sparkles",
        title: "Пока пусто",
        message: "Добавьте первую привычку, чтобы начать путь",
        actionTitle: "Добавить привычку",
        action: {}
    )
    .background(Theme.backgroundGradient(for: .dark))
}
