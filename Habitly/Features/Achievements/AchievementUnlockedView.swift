import SwiftUI

/// Полноэкранный красивый экран получения достижения — конфетти, крупный бейдж, мощный haptic.
struct AchievementUnlockedView: View {
    let kind: AchievementKind
    var onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var badgeScale: CGFloat = 0.4
    @State private var badgeOpacity: Double = 0

    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: .dark).ignoresSafeArea()
            ConfettiView().ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Spacer()

                Text("Новое достижение!")
                    .font(Typography.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .textCase(.uppercase)

                ZStack {
                    Circle()
                        .fill(Theme.brandGradient)
                        .frame(width: 160, height: 160)
                        .shadow(color: Color(hex: "9B5CFF").opacity(0.6), radius: 30, x: 0, y: 10)
                    Image(systemName: kind.symbol)
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(badgeScale)
                .opacity(badgeOpacity)

                VStack(spacing: Spacing.xs) {
                    Text(kind.title)
                        .font(Typography.title)
                        .fitsWidth(lines: 2, minScale: 0.7)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(kind.subtitle)
                        .font(Typography.body)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()

                CapsuleButton(title: "Отлично!", systemImage: "checkmark") {
                    onDismiss()
                }
                .padding(.bottom, Spacing.xl)
            }
        }
        .onAppear {
            Haptics.shared.celebration()
            if reduceMotion {
                badgeScale = 1
                badgeOpacity = 1
            } else {
                withAnimation(Motion.bouncy.delay(0.1)) {
                    badgeScale = 1
                    badgeOpacity = 1
                }
            }
        }
    }
}

#Preview {
    AchievementUnlockedView(kind: .streak30, onDismiss: {})
}
