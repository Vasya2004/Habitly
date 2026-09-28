import SwiftUI

struct AchievementsView: View {
    var body: some View {
        EmptyStateView(
            symbol: "trophy.fill",
            title: "Награды впереди",
            message: "Выполняйте привычки, чтобы открывать достижения и получать XP"
        )
    }
}

#Preview {
    AchievementsView()
}
