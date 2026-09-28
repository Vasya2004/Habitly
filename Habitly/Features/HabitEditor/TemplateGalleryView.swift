import SwiftUI

/// Библиотека готовых шаблонов привычек по категориям — быстрое заполнение черновика.
struct TemplateGalleryView: View {
    var onSelect: (HabitTemplate) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var category: HabitCategory = .health

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(HabitCategory.allCases) { cat in
                        categoryChip(cat)
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(HabitTemplate.templates(for: category)) { template in
                        templateCard(template)
                    }
                }
            }
        }
    }

    private func categoryChip(_ cat: HabitCategory) -> some View {
        let isSelected = cat == category
        return Button {
            Haptics.shared.selectionChanged()
            withAnimation(Motion.tap) { category = cat }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: cat.symbol)
                Text(cat.title)
            }
            .font(Typography.caption)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .foregroundStyle(isSelected ? .white : Theme.secondaryText(for: scheme))
            .background {
                Capsule().fill(isSelected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color.gray.opacity(0.12)))
            }
        }
        .buttonStyle(.plain)
    }

    private func templateCard(_ template: HabitTemplate) -> some View {
        Button {
            Haptics.shared.impact(.soft)
            onSelect(template)
        } label: {
            VStack(spacing: Spacing.xxs) {
                ZStack {
                    Circle().fill(HabitColor.palette[template.colorIndex].gradient)
                    HabitIconView(icon: template.icon, size: 28)
                }
                .frame(width: 40, height: 40)
                Text(template.name)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.primaryText(for: scheme))
                    .lineLimit(1)
            }
            .padding(Spacing.xs)
            .frame(width: 84)
            .cardStyle(cornerRadius: Radius.control)
        }
        .buttonStyle(.plain)
        .pressableScale()
    }
}

#Preview {
    TemplateGalleryView(onSelect: { _ in })
        .padding()
        .background(Theme.backgroundGradient(for: .dark))
}
