import SwiftUI

struct TodayView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                Text("Сегодня")
                    .font(Typography.largeTitle)
                    .foregroundStyle(Theme.primaryText(for: scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)

                ProgressRing(progress: 0)
                    .frame(width: 120, height: 120)

                HabitCard(
                    icon: "💧", title: "Пить воду", subtitle: "0 из 8 стаканов",
                    color: HabitColor.palette[1], streak: 0, progress: 0,
                    isCompleted: false, showsStepper: true,
                    onIncrement: {}, onDecrement: {}, onToggle: {}
                )
            }
            .padding(Spacing.md)
            .padding(.bottom, 100)
        }
    }
}

#Preview {
    TodayView()
}
