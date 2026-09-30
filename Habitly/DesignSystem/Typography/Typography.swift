import SwiftUI

/// Текстовые стили: SF Pro Rounded для заголовков и цифр, SF Pro для текста.
/// Все шрифты масштабируются вместе с системным Dynamic Type (UIFontMetrics),
/// поэтому увеличение текста в настройках специальных возможностей работает во всём приложении.
enum Typography {
    static func roundedFont(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        scaledFont(size: size, weight: weight, design: .rounded)
    }

    static var largeTitle: Font { roundedFont(size: 34, weight: .bold) }
    static var title: Font { roundedFont(size: 24, weight: .bold) }
    static var title2: Font { roundedFont(size: 20, weight: .semibold) }
    static var headline: Font { roundedFont(size: 17, weight: .semibold) }
    static var bigNumber: Font { roundedFont(size: 44, weight: .heavy) }
    static var mediumNumber: Font { roundedFont(size: 28, weight: .bold) }

    static var body: Font { scaledFont(size: 16, weight: .regular, design: .default) }
    static var subheadline: Font { scaledFont(size: 14, weight: .medium, design: .default) }
    static var caption: Font { scaledFont(size: 12, weight: .medium, design: .default) }

    private static func scaledFont(size: CGFloat, weight: Font.Weight, design: Font.Design) -> Font {
        let uiFont = UIFont.systemFont(ofSize: size, weight: weight.uiKitWeight)
        let systemDesign: UIFontDescriptor.SystemDesign = design == .rounded ? .rounded : .default
        let descriptor = uiFont.fontDescriptor.withDesign(systemDesign) ?? uiFont.fontDescriptor
        let designedFont = UIFont(descriptor: descriptor, size: size)
        let scaledFont = UIFontMetrics.default.scaledFont(for: designedFont)
        return Font(scaledFont)
    }
}

private extension Font.Weight {
    var uiKitWeight: UIFont.Weight {
        switch self {
        case .black: return .black
        case .heavy: return .heavy
        case .bold: return .bold
        case .semibold: return .semibold
        case .medium: return .medium
        case .regular: return .regular
        case .light: return .light
        case .thin: return .thin
        case .ultraLight: return .ultraLight
        default: return .regular
        }
    }
}

extension View {
    /// Крупный текст (заголовки, цифры) при большом Dynamic Type сжимается, а не разрывается посреди слова.
    func fitsWidth(lines: Int = 1, minScale: CGFloat = 0.5) -> some View {
        lineLimit(lines).minimumScaleFactor(minScale)
    }
}
