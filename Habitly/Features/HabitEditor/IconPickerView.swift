import SwiftUI

/// Сетка выбора иконки привычки: эмодзи или SF Symbols (хранится с префиксом "sf:").
struct IconPickerView: View {
    @Binding var selection: String
    var accentColor: HabitColor

    @State private var mode: Mode = .emoji

    private enum Mode: String, CaseIterable, Identifiable {
        case emoji, symbols
        var id: String { rawValue }

        var title: String {
            switch self {
            case .emoji: return String(localized: "Эмодзи")
            case .symbols: return String(localized: "Символы")
            }
        }
    }

    private static let emojis = [
        "⭐️", "💧", "📖", "🏋️", "🧘", "🏃", "😴", "💊", "🚶", "📝",
        "📧", "📵", "🧹", "🗣️", "🎧", "🙏", "🌬️", "👟", "🥗", "🍎",
        "☕️", "🚭", "🎨", "🎸", "💰", "🧴", "🪥", "🚴", "🏊", "🌱"
    ]

    private static let symbols = [
        "drop.fill", "book.fill", "figure.run", "heart.fill", "moon.stars.fill",
        "leaf.fill", "dumbbell.fill", "cup.and.saucer.fill", "pencil", "bed.double.fill",
        "flame.fill", "checkmark.seal.fill", "brain.head.profile", "figure.mind.and.body",
        "alarm.fill", "house.fill", "dollarsign.circle.fill", "paintbrush.fill", "music.note",
        "camera.fill", "gamecontroller.fill", "figure.walk", "bicycle", "sun.max.fill",
        "pawprint.fill", "phone.down.fill", "text.book.closed.fill", "cart.fill", "airplane", "figure.pool.swim"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 6)

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Picker("Тип иконки", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                switch mode {
                case .emoji:
                    ForEach(Self.emojis, id: \.self) { emoji in
                        cell(value: emoji, isSelected: selection == emoji) { selection = emoji }
                    }
                case .symbols:
                    ForEach(Self.symbols, id: \.self) { symbol in
                        let value = HabitIcon.sfPrefix + symbol
                        cell(value: value, isSelected: selection == value) { selection = value }
                    }
                }
            }
        }
        .onAppear {
            mode = HabitIcon.isSymbol(selection) ? .symbols : .emoji
        }
    }

    private func cell(value: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.selectionChanged()
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? AnyShapeStyle(accentColor.gradient) : AnyShapeStyle(Color.gray.opacity(0.12)))
                HabitIconView(icon: value, size: 34)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    IconPickerView(selection: .constant("💧"), accentColor: HabitColor.palette[1])
        .padding()
        .background(Theme.backgroundGradient(for: .dark))
}
