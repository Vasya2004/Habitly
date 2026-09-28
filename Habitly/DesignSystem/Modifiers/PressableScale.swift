import SwiftUI

/// Лёгкое уменьшение при нажатии (scale 0.97) с мягким haptic-откликом.
struct PressableScale: ViewModifier {
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(reduceMotion ? nil : Motion.tap, value: isPressed)
            // simultaneousGesture (а не onLongPressGesture) — чтобы не перехватывать тап
            // у обёрнутого Button и не блокировать его action.
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        Haptics.shared.impact(.soft)
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

extension View {
    func pressableScale() -> some View {
        modifier(PressableScale())
    }
}
