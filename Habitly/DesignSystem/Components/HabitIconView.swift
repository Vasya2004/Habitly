import SwiftUI

/// Иконка привычки хранится либо как эмодзи ("💧"), либо как имя SF Symbol с префиксом "sf:"
/// (например "sf:drop.fill") — так UI однозначно определяет, чем рендерить значение.
enum HabitIcon {
    static let sfPrefix = "sf:"

    static func isSymbol(_ raw: String) -> Bool { raw.hasPrefix(sfPrefix) }
    static func symbolName(_ raw: String) -> String { String(raw.dropFirst(sfPrefix.count)) }
}

/// Отображает иконку привычки — эмодзи текстом или системный символ — единым способом.
struct HabitIconView: View {
    var icon: String
    var size: CGFloat

    var body: some View {
        Group {
            if HabitIcon.isSymbol(icon) {
                Image(systemName: HabitIcon.symbolName(icon))
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(.white)
            } else {
                Text(icon.isEmpty ? "⭐️" : icon)
                    .font(.system(size: size * 0.5))
            }
        }
    }
}
