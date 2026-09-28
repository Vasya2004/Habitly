import SwiftUI

enum AppIconOption: String, CaseIterable, Identifiable {
    case `default`
    case teal = "AppIcon-Teal"
    case coral = "AppIcon-Coral"

    var id: String { rawValue }

    /// nil означает основную иконку (сбрасывает alternate icon).
    var alternateIconName: String? { self == .default ? nil : rawValue }

    var title: String {
        switch self {
        case .default: return "Классическая"
        case .teal: return "Бирюзовая"
        case .coral: return "Коралловая"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .default: return Theme.brandGradient
        case .teal: return LinearGradient(colors: [Color(hex: "38E1C4"), Color(hex: "3ABEEB")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .coral: return LinearGradient(colors: [Color(hex: "FF7A59"), Color(hex: "FFB259")], startPoint: .topLeading, endPoint: .bottomTrailing)
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(option.gradient)
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.white, lineWidth: current == option ? 2.5 : 0)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .opacity(current == option ? 1 : 0)
                    )
                Text(option.title)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText(for: scheme))
            }
        }
        .buttonStyle(.plain)
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
