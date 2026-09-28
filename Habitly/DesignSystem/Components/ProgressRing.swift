import SwiftUI

/// Кольцо прогресса. progress в диапазоне 0...1. Заполняется spring-анимацией.
struct ProgressRing: View {
    var progress: Double
    var gradient: LinearGradient = Theme.brandGradient
    var lineWidth: CGFloat = 10
    var trackOpacity: Double = 0.12

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(trackOpacity), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Motion.spring, value: clamped)
        }
    }
}

#Preview {
    ProgressRing(progress: 0.65)
        .frame(width: 160, height: 160)
        .padding()
}
