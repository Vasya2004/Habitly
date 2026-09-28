import SwiftUI

/// Текстовые стили: SF Pro Rounded для заголовков и цифр, SF Pro для текста.
enum Typography {
    static func roundedFont(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let largeTitle = roundedFont(size: 34, weight: .bold)
    static let title = roundedFont(size: 24, weight: .bold)
    static let title2 = roundedFont(size: 20, weight: .semibold)
    static let headline = roundedFont(size: 17, weight: .semibold)
    static let bigNumber = roundedFont(size: 44, weight: .heavy)
    static let mediumNumber = roundedFont(size: 28, weight: .bold)

    static let body = Font.system(size: 16, weight: .regular)
    static let subheadline = Font.system(size: 14, weight: .medium)
    static let caption = Font.system(size: 12, weight: .medium)
}
