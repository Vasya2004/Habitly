import SwiftUI

/// Горизонтальная лента выбора акцентного градиента привычки из палитры 12 цветов.
struct ColorPickerRow: View {
    @Binding var selectedIndex: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(HabitColor.palette) { color in
                    Button {
                        Haptics.shared.selectionChanged()
                        withAnimation(Motion.tap) { selectedIndex = color.id }
                    } label: {
                        Circle()
                            .fill(color.gradient)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .strokeBorder(.white, lineWidth: selectedIndex == color.id ? 2.5 : 0)
                            )
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .opacity(selectedIndex == color.id ? 1 : 0)
                            )
                            .scaleEffect(selectedIndex == color.id ? 1.1 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, Spacing.xxs)
        }
    }
}

#Preview {
    ColorPickerRow(selectedIndex: .constant(2))
        .padding()
        .background(Theme.backgroundGradient(for: .dark))
}
