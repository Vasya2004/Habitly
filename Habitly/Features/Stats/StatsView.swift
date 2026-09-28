import SwiftUI

struct StatsView: View {
    var body: some View {
        EmptyStateView(
            symbol: "chart.bar.fill",
            title: "Статистика появится здесь",
            message: "Как только вы начнёте отмечать привычки, тут появятся графики и инсайты"
        )
    }
}

#Preview {
    StatsView()
}
