import SwiftUI

/// Убирает стандартный фон/разделитель строки List и задаёт отступы под сетку дизайн-системы.
/// Используется для нестандартных элементов (шапка, лента недели, кольцо прогресса) внутри List.
extension View {
    func plainRow(top: CGFloat = 0, bottom: CGFloat = 0) -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: top, leading: Spacing.md, bottom: bottom, trailing: Spacing.md))
    }
}
