import SwiftUI

/// Стеклянная карточка: .ultraThinMaterial, крупное скругление, тонкая градиентная обводка, мягкая тень.
struct CardBackground: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var cornerRadius: CGFloat = Radius.card

    func body(content: Content) -> some View {
        content
            // Заливка вместо .ultraThinMaterial: фон приложения — ровный градиент, размытию под карточкой
            // нечего показывать, а полупрозрачный блюр на каждой карточке заметно грузит видеокарту при прокрутке
            // и переходах между вкладками.
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(scheme == .dark ? Color.white.opacity(0.11) : Color.black.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.cardStroke(for: scheme), lineWidth: 1)
            )
            .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.08), radius: 18, x: 0, y: 10)
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = Radius.card) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }
}
