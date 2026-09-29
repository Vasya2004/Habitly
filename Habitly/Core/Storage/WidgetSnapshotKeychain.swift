import Foundation
import Security

/// Мост «приложение → виджет» через общую группу Keychain — запасной путь на случай, когда
/// App Group недоступна. Обе цели подписываются с одной и той же keychain-access-groups,
/// поэтому элемент без явной группы попадает в общую (первую в списке entitlements).
enum WidgetSnapshotKeychain {
    private static let service = "com.danko.habitly.widget-bridge"
    private static let snapshotAccount = "snapshot"
    private static let pendingAccount = "pending-toggles"

    // MARK: - Снимок для виджета

    static func writeSnapshot(_ data: HabitlyWidgetData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        write(encoded, account: snapshotAccount)
    }

    static func readSnapshot() -> HabitlyWidgetData? {
        guard let data = read(account: snapshotAccount) else { return nil }
        return try? JSONDecoder().decode(HabitlyWidgetData.self, from: data)
    }

    // MARK: - Отметки, сделанные с виджета и ожидающие применения в приложении

    static func appendPendingToggle(_ habitID: String) {
        write(encodePending(readPendingToggles() + [habitID]), account: pendingAccount)
    }

    static func readPendingToggles() -> [String] {
        guard let data = read(account: pendingAccount),
              let ids = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return ids
    }

    static func clearPendingToggles() {
        SecItemDelete(baseQuery(account: pendingAccount) as CFDictionary)
    }

    private static func encodePending(_ ids: [String]) -> Data {
        (try? JSONEncoder().encode(ids)) ?? Data()
    }

    // MARK: - Keychain

    private static func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private static func write(_ data: Data, account: String) {
        SecItemDelete(baseQuery(account: account) as CFDictionary)
        var query = baseQuery(account: account)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func read(account: String) -> Data? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }
}
