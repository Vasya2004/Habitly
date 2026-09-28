import SwiftUI

/// Кнопка-капсула с фирменным градиентом.
struct CapsuleButton: View {
    var title: String
    var systemImage: String?
    var isProminent: Bool = true
    var action: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: {
            Haptics.shared.impact(.soft)
            action()
        }) {
            HStack(spacing: Spacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(Typography.headline)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .foregroundStyle(isProminent ? .white : Theme.primaryText(for: scheme))
            .background {
                if isProminent {
                    Capsule().fill(Theme.brandGradient)
                } else {
                    Capsule().fill(.ultraThinMaterial)
                }
            }
        }
        .buttonStyle(.plain)
        .pressableScale()
    }
}

#Preview {
    VStack(spacing: 16) {
        CapsuleButton(title: "Добавить привычку", systemImage: "plus") {}
        CapsuleButton(title: "Отмена", isProminent: false) {}
    }
    .padding()
}
