import SwiftUI

enum MainTab: Int, CaseIterable, Identifiable {
    case today, stats, achievements, settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .today: return String(localized: "Сегодня")
        case .stats: return String(localized: "Статистика")
        case .achievements: return String(localized: "Награды")
        case .settings: return String(localized: "Настройки")
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

    @Namespace private var selectionNamespace
    @State private var tabFrames: [MainTab: CGRect] = [:]

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                glassBar
            } else {
                materialBar
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var items: some View {
        HStack(spacing: 0) {
            ForEach(leftTabs) { tab in tabButton(tab) }
            addButton
            ForEach(rightTabs) { tab in tabButton(tab) }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .coordinateSpace(name: "tabBar")
        // Можно вести пальцем по меню — стеклянный индикатор перетекает за пальцем.
        .simultaneousGesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .named("tabBar"))
                .onChanged { drag in
                    if let tab = tabFrames.first(where: { $0.value.contains(drag.location) })?.key {
                        select(tab)
                    }
                }
        )
    }

    private func select(_ tab: MainTab) {
        guard tab != selection else { return }
        Haptics.shared.selectionChanged()
        withAnimation(Motion.bouncy) { selection = tab }
    }

    /// iOS 26+: настоящее стекло Liquid Glass, реагирует на касание и подсвечивает содержимое под собой.
    @available(iOS 26.0, *)
    private var glassBar: some View {
        GlassEffectContainer {
            items.glassEffect(.regular.interactive(), in: .capsule)
        }
    }

    /// iOS 17–25: прежний матовый материал.
    private var materialBar: some View {
        items
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(scheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1))
            .shadow(color: .black.opacity(scheme == .dark ? 0.2 : 0.12), radius: 20, x: 0, y: 10)
    }

    private func tabButton(_ tab: MainTab) -> some View {
        Button {
            select(tab)
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
            .background { selectionIndicator(for: tab) }
        }
        .buttonStyle(.plain)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("tabBar")) } action: { tabFrames[tab] = $0 }
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selection == tab ? [.isButton, .isSelected] : .isButton)
    }

    /// Индикатор выбранной вкладки: на iOS 26 — стеклянная «капля», которая перетекает между вкладками.
    @ViewBuilder
    private func selectionIndicator(for tab: MainTab) -> some View {
        if selection == tab {
            if #available(iOS 26.0, *) {
                Capsule()
                    .fill(Color.clear)
                    .glassEffect(.regular.tint(Color(hex: "7C5CFF").opacity(0.35)).interactive(), in: .capsule)
                    .glassEffectID("tabSelection", in: selectionNamespace)
            } else {
                Capsule()
                    .fill(Color(hex: "7C5CFF").opacity(scheme == .dark ? 0.28 : 0.14))
                    .matchedGeometryEffect(id: "tabSelection", in: selectionNamespace)
            }
        }
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
