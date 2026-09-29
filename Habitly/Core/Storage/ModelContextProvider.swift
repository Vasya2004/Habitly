import SwiftData

/// Синглтон с ModelContext поверх общего App Group контейнера — используется виджетом
/// и App Intent'ами, у которых нет SwiftUI-окружения для @Environment(\.modelContext).
final class ModelContextProvider {
    static let shared = ModelContextProvider()

    let container: ModelContainer
    let context: ModelContext

    private init() {
        container = SharedModelContainer.make()
        context = ModelContext(container)
    }
}
