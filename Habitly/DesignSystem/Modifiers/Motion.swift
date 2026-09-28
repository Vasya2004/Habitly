import SwiftUI

/// Единые spring-анимации приложения.
enum Motion {
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let tap = Animation.spring(response: 0.25, dampingFraction: 0.6)
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.65)
}
