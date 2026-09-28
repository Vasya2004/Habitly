import SwiftUI

/// Лёгкое конфетти без внешних зависимостей — показывается при выполнении всех привычек за день.
/// Уважает Reduce Motion: при включённой настройке эффект не рендерится вовсе.
struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pieces: [Piece] = []

    private struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let duration: Double
        let color: Color
        let rotation: Double
        let size: CGFloat
    }

    private let colors: [Color] = HabitColor.palette.flatMap { [$0.start, $0.end] }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPiece(piece: piece, height: proxy.size.height)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                pieces = (0..<40).map { _ in
                    Piece(
                        x: CGFloat.random(in: 0...proxy.size.width),
                        delay: Double.random(in: 0...0.3),
                        duration: Double.random(in: 1.4...2.2),
                        color: colors.randomElement() ?? .purple,
                        rotation: Double.random(in: 0...360),
                        size: CGFloat.random(in: 6...12)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private struct ConfettiPiece: View {
        let piece: Piece
        let height: CGFloat
        @State private var animate = false

        var body: some View {
            RoundedRectangle(cornerRadius: 2)
                .fill(piece.color)
                .frame(width: piece.size, height: piece.size * 0.4)
                .rotationEffect(.degrees(animate ? piece.rotation + 180 : piece.rotation))
                .position(x: piece.x, y: animate ? height + 40 : -20)
                .opacity(animate ? 0 : 1)
                .onAppear {
                    withAnimation(.easeIn(duration: piece.duration).delay(piece.delay)) {
                        animate = true
                    }
                }
        }
    }
}

#Preview {
    ZStack {
        Theme.backgroundGradient(for: .dark).ignoresSafeArea()
        ConfettiView()
    }
}
