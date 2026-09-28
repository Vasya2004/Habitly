import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                Text("Настройки")
                    .font(Typography.largeTitle)
                    .foregroundStyle(Theme.primaryText(for: scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.md)
        }
    }
}

#Preview {
    SettingsView()
}
