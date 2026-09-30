import SwiftUI

enum AppIconOption: String, CaseIterable, Identifiable {
    case `default`
    case ember = "AppIcon-Ember"
    case sunset = "AppIcon-Sunset"

    var id: String { rawValue }

    /// nil означает основную иконку (сбрасывает alternate icon).
    var alternateIconName: String? { self == .default ? nil : rawValue }

    var title: String {
        switch self {
        case .default: return "Классическая"
        case .ember: return "Огненная"
        case .sunset: return "Закатная"
        }
    }

    /// Имя превью в каталоге ассетов — та же картинка, что и у самой иконки.
    var previewImageName: String {
        switch self {
        case .default: return "IconPreviewClassic"
        case .ember: return "IconPreviewEmber"
        case .sunset: return "IconPreviewSunset"
        }
    }
}

/// Ряд выбора иконки приложения — настоящие alternate icons через UIApplication.
struct AppIconPickerRow: View {
    @Environment(\.colorScheme) private var scheme
    @State private var current: AppIconOption = {
        guard let name = UIApplication.shared.alternateIconName, let option = AppIconOption(rawValue: name) else {
            return .default
        }
        return option
    }()
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.md) {
                ForEach(AppIconOption.allCases) { option in
                    iconButton(option)
                }
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(Typography.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func iconButton(_ option: AppIconOption) -> some View {
        Button {
            select(option)
        } label: {
            VStack(spacing: Spacing.xxs) {
                Image(option.previewImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                    )
                    .padding(3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .strokeBorder(Theme.brandGradient, lineWidth: current == option ? 3 : 0)
                    )
                Text(option.title)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText(for: scheme))
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(current == option ? [.isButton, .isSelected] : .isButton)
    }

    private func select(_ option: AppIconOption) {
        guard current != option else { return }
        Haptics.shared.selectionChanged()
        UIApplication.shared.setAlternateIconName(option.alternateIconName) { error in
            if let error {
                errorMessage = "Не удалось сменить иконку: \(error.localizedDescription)"
            } else {
                errorMessage = nil
                current = option
            }
        }
    }
}

#Preview {
    AppIconPickerRow()
        .padding()
        .background(Theme.backgroundGradient(for: .dark))
}
