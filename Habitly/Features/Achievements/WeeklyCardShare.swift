import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

/// Карточка «Итоги недели» для отправки: PNG рисуется только когда пользователь нажал «Поделиться».
struct WeeklyCardShare: Transferable {
    let data: WeeklySummaryData
    let profileName: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            try await MainActor.run {
                let renderer = ImageRenderer(content: WeeklySummaryCardView(data: item.data, profileName: item.profileName))
                renderer.scale = 3
                guard let png = renderer.uiImage?.pngData() else { throw CocoaError(.fileWriteUnknown) }
                return png
            }
        }
    }
}
