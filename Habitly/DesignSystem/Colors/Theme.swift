import SwiftUI

/// Фирменные цвета и градиенты приложения.
enum Theme {
    /// Фирменный градиент: фиолетовый → розовый.
    static let brandGradient = LinearGradient(
        colors: [Color(hex: "7C5CFF"), Color(hex: "FF5CA6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        switch scheme {
        case .dark:
            return LinearGradient(
                colors: [Color(hex: "0B0B12"), Color(hex: "14142B")],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [Color(hex: "F6F5FF"), Color(hex: "FFFFFF")],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    static func cardStroke(for scheme: ColorScheme) -> LinearGradient {
        let colors: [Color] = scheme == .dark
            ? [Color.white.opacity(0.18), Color.white.opacity(0.02)]
            : [Color(hex: "14142B").opacity(0.12), Color(hex: "14142B").opacity(0.05)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func primaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : Color(hex: "14142B")
    }

    static func secondaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.6) : Color(hex: "14142B").opacity(0.55)
    }
}

/// Акцентный цвет привычки — градиентная пара из палитры 12 цветов.
struct HabitColor: Identifiable, Equatable {
    let id: Int
    let name: String
    let start: Color
    let end: Color

    var gradient: LinearGradient {
        LinearGradient(colors: [start, end], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let palette: [HabitColor] = [
        HabitColor(id: 0, name: String(localized: "Коралл"), start: Color(hex: "FF7A59"), end: Color(hex: "FFB259")),
        HabitColor(id: 1, name: String(localized: "Бирюза"), start: Color(hex: "38E1C4"), end: Color(hex: "3ABEEB")),
        HabitColor(id: 2, name: String(localized: "Орхидея"), start: Color(hex: "9B5CFF"), end: Color(hex: "FF5CA6")),
        HabitColor(id: 3, name: String(localized: "Лайм"), start: Color(hex: "A6E13D"), end: Color(hex: "3ED17A")),
        HabitColor(id: 4, name: String(localized: "Небо"), start: Color(hex: "5C9BFF"), end: Color(hex: "5CE1FF")),
        HabitColor(id: 5, name: String(localized: "Малина"), start: Color(hex: "FF5C7A"), end: Color(hex: "FF9A5C")),
        HabitColor(id: 6, name: String(localized: "Янтарь"), start: Color(hex: "FFC65C"), end: Color(hex: "FF8A5C")),
        HabitColor(id: 7, name: String(localized: "Индиго"), start: Color(hex: "5C6CFF"), end: Color(hex: "9B5CFF")),
        HabitColor(id: 8, name: String(localized: "Изумруд"), start: Color(hex: "2ED17A"), end: Color(hex: "38E1C4")),
        HabitColor(id: 9, name: String(localized: "Роза"), start: Color(hex: "FF5CD1"), end: Color(hex: "FF5C7A")),
        HabitColor(id: 10, name: String(localized: "Океан"), start: Color(hex: "3ABEEB"), end: Color(hex: "5C6CFF")),
        HabitColor(id: 11, name: String(localized: "Лаванда"), start: Color(hex: "B25CFF"), end: Color(hex: "5C9BFF"))
    ]
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
