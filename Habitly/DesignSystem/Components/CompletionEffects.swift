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

private struct ProgressValue { var progress = 0.0 }

// MARK: - Частицы

/// Салют из частиц с физикой: разлёт, торможение, падение под силой тяжести, вращение.
/// Рисуется в Canvas по одному триггеру; в покое ничего не рендерит.
struct ParticleBurst: View {
    var trigger: Int
    var color: HabitColor

    private struct Particle {
        let angle: Double
        let speed: Double
        let size: Double
        let kind: Int          // 0 — круг, 1 — искра, 2 — конфетти
        let spin: Double
        let life: Double
        let colorIndex: Int
    }

    @State private var particles: [Particle] = []
    @State private var startDate: Date?

    private let duration = 1.6
    private let gold = Color(hex: "FFC65C")

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: startDate == nil)) { timeline in
            Canvas { context, size in
                guard let startDate else { return }
                let t = timeline.date.timeIntervalSince(startDate)
                guard t >= 0, t < duration else { return }
                let origin = CGPoint(x: size.width / 2, y: size.height / 2)
                drawGlow(&context, origin: origin, t: t)
                drawRings(&context, origin: origin, t: t)
                drawParticles(&context, origin: origin, t: t)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _, _ in spawn() }
    }

    private func spawn() {
        particles = (0..<34).map { i in
            Particle(
                angle: Double.random(in: 0..<(2 * .pi)),
                speed: Double.random(in: 150...360),
                size: Double.random(in: 4...9),
                kind: i % 5 == 0 ? 1 : (i % 3 == 0 ? 2 : 0),
                spin: Double.random(in: -9...9),
                life: Double.random(in: 0.9...1.5),
                colorIndex: Int.random(in: 0..<5)
            )
        }
        startDate = .now
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) { startDate = nil }
    }

    // MARK: рисование

    private func drawGlow(_ context: inout GraphicsContext, origin: CGPoint, t: Double) {
        let span = 0.45
        guard t < span else { return }
        let p = t / span
        let radius = 26 + 40 * p
        let rect = CGRect(x: origin.x - radius, y: origin.y - radius, width: radius * 2, height: radius * 2)
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(colors: [color.start.opacity(0.55 * (1 - p)), color.start.opacity(0)]),
                center: origin, startRadius: 0, endRadius: radius
            )
        )
    }

    private func drawRings(_ context: inout GraphicsContext, origin: CGPoint, t: Double) {
        for (index, delay) in [0.0, 0.12].enumerated() {
            let p = (t - delay) / 0.55
            guard p > 0, p < 1 else { continue }
            let eased = 1 - pow(1 - p, 3)
            let radius = 16 + 62 * eased
            let rect = CGRect(x: origin.x - radius, y: origin.y - radius, width: radius * 2, height: radius * 2)
            let tint = index == 0 ? color.start : color.end
            context.stroke(Path(ellipseIn: rect), with: .color(tint.opacity((1 - p) * 0.75)), lineWidth: max(0.6, 3.2 * (1 - p)))
        }
    }

    private func drawParticles(_ context: inout GraphicsContext, origin: CGPoint, t: Double) {
        let palette = [color.start, color.end, gold, color.start, color.end]
        let drag = 3.2
        let gravity = 320.0
        for particle in particles {
            let age = t / particle.life
            guard age < 1 else { continue }
            let travel = (1 - exp(-drag * t)) / drag
            let x = origin.x + cos(particle.angle) * particle.speed * travel
            let y = origin.y + sin(particle.angle) * particle.speed * travel + 0.5 * gravity * t * t

            let pop = min(t / 0.08, 1)
            let fade = age < 0.6 ? 1 : max(0, 1 - (age - 0.6) / 0.4)
            let scale = pop * (1 - 0.55 * age)

            var ctx = context
            ctx.translateBy(x: x, y: y)
            ctx.rotate(by: .radians(particle.spin * t))
            ctx.opacity = fade
            let s = particle.size * scale
            let fill = GraphicsContext.Shading.color(palette[particle.colorIndex])
            switch particle.kind {
            case 1:
                ctx.fill(sparkle(radius: s * 1.6), with: fill)
            case 2:
                ctx.fill(Path(roundedRect: CGRect(x: -s * 0.9, y: -s * 0.4, width: s * 1.8, height: s * 0.8), cornerRadius: 1.5), with: fill)
            default:
                ctx.fill(Path(ellipseIn: CGRect(x: -s / 2, y: -s / 2, width: s, height: s)), with: fill)
            }
        }
    }

    /// Четырёхконечная искра.
    private func sparkle(radius r: Double) -> Path {
        var path = Path()
        let inner = r * 0.28
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4 - .pi / 2
            let radius = i % 2 == 0 ? r : inner
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Перелив цвета

/// Цвет привычки «переливается» по карточке слева направо один раз: широкая мягкая световая полоса
/// с цветным шлейфом и светлым ядром; за ней карточка остаётся насыщенно подкрашенной.
struct CompletionWash: View, Animatable {
    /// Положение света: 0 — за левым краем, 1 — за правым.
    var progress: CGFloat
    var color: HabitColor

    /// Без этого SwiftUI не интерполирует progress между кадрами и анимация «прыгает» в конечное состояние.
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let band = w * 0.75
            let p = min(max(progress, 0), 1)
            let sheen = sin(Double.pi * Double(p))
            let x = -band / 2 + p * (w + band)
            let isDark = scheme == .dark

            ZStack {
                // базовая подкраска — есть сразу
                Rectangle().fill(color.gradient.opacity(isDark ? 0.18 : 0.20))

                // более насыщенный «шлейф»: заливается позади светового фронта и остаётся.
                // Передний край мягкий (градиентная маска), без резкой вертикальной границы.
                Rectangle()
                    .fill(color.gradient.opacity(isDark ? 0.22 : 0.18))
                    .mask {
                        let center = Double((x + band * 0.1) / max(w, 1))
                        let feather = 0.34
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: min(max(center - feather / 2, 0), 1)),
                                .init(color: .clear, location: min(max(center + feather / 2, 0.0001), 1))
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                    }

                // широкая цветная полоса — «жидкий» цвет, чуть наклонённая и размытая
                LinearGradient(
                    stops: [
                        .init(color: color.start.opacity(0), location: 0),
                        .init(color: color.start.opacity(0.55), location: 0.30),
                        .init(color: color.end.opacity(0.95), location: 0.58),
                        .init(color: color.end.opacity(0.35), location: 0.82),
                        .init(color: color.end.opacity(0), location: 1)
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: band, height: h * 2.2)
                .rotationEffect(.degrees(14))
                .blur(radius: 10)
                .position(x: x, y: h / 2)
                .opacity(sheen)

                // светлое ядро — «проход света»
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0), location: 0),
                        .init(color: .white.opacity(isDark ? 0.55 : 0.85), location: 0.5),
                        .init(color: .white.opacity(0), location: 1)
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: band * 0.3, height: h * 2.2)
                .rotationEffect(.degrees(14))
                .blur(radius: 6)
                .position(x: x + band * 0.05, y: h / 2)
                .blendMode(isDark ? .plusLighter : .normal)
                .opacity(sheen)
            }
            .frame(width: w, height: h)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Светящаяся кромка карточки: яркое пятно света бежит по контуру один круг и гаснет.
struct CompletionEdgeGlow: View, Animatable {
    var progress: CGFloat
    var color: HabitColor
    var cornerRadius: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let p = min(max(progress, 0), 1)
        let envelope = sin(Double.pi * Double(p))
        let gradient = AngularGradient(
            stops: [
                .init(color: color.start.opacity(0), location: 0.00),
                .init(color: color.start.opacity(0), location: 0.45),
                .init(color: color.end, location: 0.75),
                .init(color: .white, location: 0.92),
                .init(color: color.start.opacity(0), location: 1.00)
            ],
            center: .center,
            angle: .degrees(-90 + 360 * Double(p))
        )
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack {
            shape.strokeBorder(gradient, lineWidth: 12).blur(radius: 10)   // широкое мягкое свечение
            shape.strokeBorder(gradient, lineWidth: 5).blur(radius: 3)     // ближнее свечение
            shape.strokeBorder(gradient, lineWidth: 2.5)                   // яркая кромка
        }
        .opacity(min(1, envelope * 1.4))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Награда XP

/// «+10 XP», всплывающая над галочкой.
struct XPFloater: View {
    var trigger: Int
    var amount: Int
    var color: HabitColor

    private struct Values {
        var offset = -22.0
        var opacity = 0.0
        var scale = 0.6
    }

    var body: some View {
        // Анимация применяется прямо к значку, чтобы он сохранял собственный размер.
        Text("+\(amount) XP")
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.gradient))
            .shadow(color: color.start.opacity(0.55), radius: 6, y: 2)
            .keyframeAnimator(initialValue: Values(), trigger: trigger) { content, v in
                content
                    .scaleEffect(v.scale)
                    // левее галочки, чтобы не перекрывать счётчик секции над карточкой
                    .offset(x: -40, y: v.offset)
                    .opacity(v.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.offset) {
                    CubicKeyframe(-46, duration: 1.2)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0, duration: 0.12)
                    CubicKeyframe(1, duration: 0.14)
                    LinearKeyframe(1, duration: 0.6)
                    CubicKeyframe(0, duration: 0.4)
                }
                KeyframeTrack(\.scale) {
                    LinearKeyframe(0.6, duration: 0.12)
                    SpringKeyframe(1.12, duration: 0.25, spring: .bouncy)
                    SpringKeyframe(1, duration: 0.3)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Вспышка вокруг иконки

/// Кольцо, расходящееся от иконки привычки, когда цель выполнена.
struct IconFlash: View {
    var trigger: Int
    var color: HabitColor

    var body: some View {
        Color.clear
            .keyframeAnimator(initialValue: ProgressValue(), trigger: trigger) { _, value in
                let p = value.progress
                Circle()
                    .strokeBorder(color.gradient, lineWidth: max(0.5, 4 * (1 - p)))
                    .scaleEffect(1 + p * 0.7)
                    .opacity(p == 0 || p == 1 ? 0 : (1 - p) * 0.85)
            } keyframes: { _ in
                KeyframeTrack(\.progress) {
                    LinearKeyframe(0, duration: 0.25)
                    CubicKeyframe(1, duration: 0.6)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Отскок кнопки

private struct ButtonScale { var scale = 1.0 }

extension View {
    /// Кнопка «сжимается» под пальцем и пружинно отскакивает при каждом срабатывании триггера.
    func completionSquash(trigger: Int) -> some View {
        keyframeAnimator(initialValue: ButtonScale(), trigger: trigger) { content, value in
            content.scaleEffect(value.scale)
        } keyframes: { _ in
            KeyframeTrack(\.scale) {
                CubicKeyframe(0.78, duration: 0.09)
                SpringKeyframe(1.28, duration: 0.22, spring: .bouncy)
                SpringKeyframe(1.0, duration: 0.3, spring: .smooth)
            }
        }
    }
}
