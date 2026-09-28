import UIKit

/// Централизованный сервис тактильной отдачи. Уважает настройку пользователя в Profile.hapticsEnabled.
final class Haptics {
    static let shared = Haptics()
    var isEnabled = true

    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private init() {}

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        switch style {
        case .soft: impactSoft.impactOccurred()
        case .rigid: impactRigid.impactOccurred()
        default: impactMedium.impactOccurred()
        }
    }

    func success() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }

    func warning() {
        guard isEnabled else { return }
        notification.notificationOccurred(.warning)
    }

    func selectionChanged() {
        guard isEnabled else { return }
        selection.selectionChanged()
    }

    /// Мощный отклик при выполнении всех привычек за день.
    func celebration() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.impactRigid.impactOccurred()
        }
    }
}
