import SwiftUI

/// Список напоминаний (времена суток) с добавлением и удалением.
struct ReminderEditorView: View {
    @Binding var reminders: [Date]

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ForEach(reminders.indices, id: \.self) { index in
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Theme.brandGradient)
                    DatePicker("", selection: $reminders[index], displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    Spacer()
                    Button {
                        Haptics.shared.impact(.soft)
                        reminders.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                Haptics.shared.impact(.soft)
                let defaultTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
                reminders.append(defaultTime)
            } label: {
                Label("Добавить напоминание", systemImage: "plus.circle.fill")
                    .font(Typography.subheadline)
                    .foregroundStyle(Theme.brandGradient)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    ReminderEditorView(reminders: .constant([.now]))
        .padding()
        .background(Theme.backgroundGradient(for: .dark))
}
