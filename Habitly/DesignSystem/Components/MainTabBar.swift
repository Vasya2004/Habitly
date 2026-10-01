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

    private enum BarItem: Hashable {
        case tab(MainTab)
        case add
    }

    /// Горизонтальные границы элементов меню (в координатах бара) — по ним определяем, куда попал палец.
    @State private var frames: [BarItem: CGRect] = [:]
    @State private var isDragging = false
    @State private var addPressed = false

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
            ForEach(leftTabs) { tab in tabItem(tab) }
            addItem
            ForEach(rightTabs) { tab in tabItem(tab) }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .coordinateSpace(name: "tabBar")
        // Вся капсула — одна зона касания: нажатие в любом месте ячейки срабатывает, а не только на иконке.
        .contentShape(Capsule())
        .gesture(barGesture)
    }

    /// Единый жест на всё меню: короткое касание — выбор вкладки (или «+»), движение пальцем — индикатор едет за ним.
    /// Одна точка обработки вместо кнопок + отдельного перетаскивания: жесты больше не мешают друг другу.
    private var barGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("tabBar"))
            .onChanged { value in
                let moved = hypot(value.translation.width, value.translation.height) > 10
                if moved { isDragging = true }
                let item = item(atX: value.location.x)
                addPressed = !isDragging && item == .add
                if isDragging, case .tab(let tab)? = item { select(tab) }
            }
            .onEnded { value in
                defer { isDragging = false; addPressed = false }
                guard !isDragging else { return }
                switch item(atX: value.location.x) {
                case .add?:
                    Haptics.shared.impact(.rigid)
                    onAdd()
                case .tab(let tab)?:
                    select(tab)
                case nil:
                    break
                }
            }
    }

    /// Элемент под пальцем определяем только по X: бар — одна строка, так надёжнее, чем попадание по точке.
    private func item(atX x: CGFloat) -> BarItem? {
        frames.first { $0.value.minX <= x && x <= $0.value.maxX }?.key
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

    private func tabItem(_ tab: MainTab) -> some View {
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
        .frame(minHeight: 52)
        .background { selectionIndicator(for: tab) }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("tabBar")) } action: { frames[.tab(tab)] = $0 }
        // Касания обрабатывает жест всего меню, а для VoiceOver элемент остаётся кнопкой.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selection == tab ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction { select(tab) }
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

    private var addItem: some View {
        Image(systemName: "plus")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 52, height: 52)
            .background(Theme.brandGradient, in: Circle())
            .shadow(color: Color(hex: "9B5CFF").opacity(0.5), radius: 12, x: 0, y: 6)
            .scaleEffect(addPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: addPressed)
            .offset(y: -6)
            .padding(.horizontal, 6)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("tabBar")) } action: { frames[.add] = $0 }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Добавить привычку")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onAdd() }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Theme.backgroundGradient(for: .dark).ignoresSafeArea()
        MainTabBar(selection: .constant(.today)) {}
            .padding(.bottom, 20)
    }
}
