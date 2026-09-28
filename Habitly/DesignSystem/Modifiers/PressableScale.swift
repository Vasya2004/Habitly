import SwiftUI

/// Лёгкое уменьшение при нажатии (scale 0.97) с мягким haptic-откликом.
struct PressableScale: ViewModifier {
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(reduceMotion ? nil : Motion.tap, value: isPressed)
            .onLongPressGesture(minimumDuration: 100, maximumDistance: 30) {
                // no-op: используется только для распознавания долгого нажатия там, где нужно
            } onPressingChanged: { pressing in
                isPressed = pressing
                if pressing {
                    Haptics.shared.impact(.soft)
                }
            }
    }
}

extension View {
    func pressableScale() -> some View {
        modifier(PressableScale())
    }
}
