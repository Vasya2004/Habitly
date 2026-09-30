import SwiftUI

/// Галочка, которая «рисуется» штрихом (trim 0...1).
struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.54))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.43, y: rect.minY + rect.height * 0.72))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.77, y: rect.minY + rect.height * 0.32))
        return path
    }
}

private struct BurstValues { var progress = 0.0 }

/// Салют при выполнении: кольцо-волна и искры, разлетающиеся от галочки. Рисуется по одному триггеру.
struct CompletionBurst: View {
    var trigger: Int
    var color: HabitColor

    private let spark = Color(hex: "FFC65C")

    var body: some View {
        Color.clear
            .frame(width: 44, height: 44)
            .keyframeAnimator(initialValue: BurstValues(), trigger: trigger) { _, value in
                burst(progress: value.progress)
            } keyframes: { _ in
                KeyframeTrack(\.progress) {
                    CubicKeyframe(1, duration: 0.75)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func burst(progress p: Double) -> some View {
        let eased = 1 - pow(1 - p, 3)
        return ZStack {
            // волна
            Circle()
                .stroke(color.start, lineWidth: max(0.5, 3 * (1 - p)))
                .frame(width: 30, height: 30)
                .scaleEffect(0.5 + eased * 2.0)
                .opacity((1 - p) * 0.7)

            // искры
            ForEach(0..<12, id: \.self) { i in
                let angle = Double(i) / 12 * 2 * .pi
                let long = i % 2 == 0
                Circle()
                    .fill([color.start, color.end, spark][i % 3])
                    .frame(width: long ? 6 : 4, height: long ? 6 : 4)
                    .scaleEffect(1 - p * 0.7)
                    .offset(x: cos(angle) * (long ? 32 : 22) * eased, y: sin(angle) * (long ? 32 : 22) * eased)
                    .opacity(1 - pow(p, 2))
            }
        }
        .frame(width: 44, height: 44)
        .opacity(p == 0 || p == 1 ? 0 : 1)
    }
}

/// Блик, один раз пробегающий по карточке слева направо.
struct ShimmerSweep: View {
    var trigger: Int
    var color: Color

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .keyframeAnimator(initialValue: BurstValues(), trigger: trigger) { _, value in
                    let p = value.progress
                    LinearGradient(
                        colors: [color.opacity(0), color.opacity(0.5), color.opacity(0)],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.55)
                    .offset(x: -geo.size.width * 0.55 + p * geo.size.width * 1.55)
                    .opacity(p == 0 || p == 1 ? 0 : 1)
                } keyframes: { _ in
                    KeyframeTrack(\.progress) {
                        LinearKeyframe(1, duration: 0.85)
                    }
                }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
