import SwiftUI

enum MainTab: Int, CaseIterable, Identifiable {
    case today, stats, achievements, settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .today: return "Сегодня"
        case .stats: return "Статистика"
        case .achievements: return "Награды"
        case .settings: return "Настройки"
        }
    }

    var symbol: String {
        switch self {
        case .today: return "checkmark.circle.fill"
        case .stats: return "chart.bar.fill"
        case .achievements: return "trophy.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

/// Кастомный таб-бар с плавающей кнопкой "+" по центру.
struct MainTabBar: View {
    @Environment(\.colorScheme) private var scheme
    @Binding var selection: MainTab
    var onAdd: () -> Void

    private let leftTabs: [MainTab] = [.today, .stats]
    private let rightTabs: [MainTab] = [.achievements, .settings]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(leftTabs) { tab in tabButton(tab) }
            addButton
            ForEach(rightTabs) { tab in tabButton(tab) }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(scheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(scheme == .dark ? 0.2 : 0.12), radius: 20, x: 0, y: 10)
        .padding(.horizontal, Spacing.lg)
    }

    private func tabButton(_ tab: MainTab) -> some View {
        Button {
            Haptics.shared.selectionChanged()
            withAnimation(Motion.tap) { selection = tab }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .symbolVariant(selection == tab ? .fill : .none)
                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(tabColor(selected: selection == tab))
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selection == tab ? [.isButton, .isSelected] : .isButton)
    }

    /// В тёмной теме — белый, в светлой — фирменный фиолетовый для активной и серый для неактивной вкладки.
    private func tabColor(selected: Bool) -> Color {
        if scheme == .dark {
            return selected ? .white : Color.white.opacity(0.45)
        }
        return selected ? Color(hex: "7C5CFF") : Color.black.opacity(0.45)
    }

    private var addButton: some View {
        Button {
            Haptics.shared.impact(.rigid)
            onAdd()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Theme.brandGradient, in: Circle())
                .shadow(color: Color(hex: "9B5CFF").opacity(0.5), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .pressableScale()
        .offset(y: -6)
        .accessibilityLabel("Добавить привычку")
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Theme.backgroundGradient(for: .dark).ignoresSafeArea()
        MainTabBar(selection: .constant(.today)) {}
            .padding(.bottom, 20)
    }
}
