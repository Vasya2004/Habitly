import SwiftUI

/// Анимированная иллюстрация из чистых SwiftUI-фигур и градиентов (без внешних картинок):
/// пульсирующие концентрические кольца с символом по центру.
struct OnboardingIllustration: View {
    var symbol: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false
    @State private var rotate = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Theme.brandGradient, lineWidth: 1.5)
                    .frame(width: 140 + CGFloat(index) * 55, height: 140 + CGFloat(index) * 55)
                    .opacity(pulse ? 0.15 : 0.5)
                    .scaleEffect(pulse ? 1.08 : 0.96)
            }

            Circle()
                .fill(Theme.brandGradient)
                .frame(width: 128, height: 128)
                .shadow(color: Color(hex: "9B5CFF").opacity(0.45), radius: 24, x: 0, y: 12)
                .rotationEffect(.degrees(rotate ? 8 : -8))

            Image(systemName: symbol)
                .font(.system(size: 50, weight: .semibold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(height: 260)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) {
                rotate = true
            }
        }
    }
}

#Preview {
    OnboardingIllustration(symbol: "sparkles")
        .background(Theme.backgroundGradient(for: .dark))
}
