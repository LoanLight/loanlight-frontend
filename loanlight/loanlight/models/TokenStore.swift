import Foundation
import Security

// MARK: - TokenStore
// Stores the JWT in the iOS Keychain.

enum TokenStore {

    private static let service = "com.loanlight.jwt"
    private static let account = "access_token"

    // MARK: - Read

    static var token: String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      account,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8)
        else { return nil }
        return str
    }

    // MARK: - Write

    static func save(_ token: String) {
        let data = Data(token.utf8)
        // Try update first
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        let attrs: [CFString: Any] = [kSecValueData: data]
        let status = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)

        if status == errSecItemNotFound {
            var add = query
            add[kSecValueData] = data
            SecItemAdd(add as CFDictionary, nil)
        }
    }

    // MARK: - Clear (named clearToken to avoid collision with Swift stdlib delete())

    static func clearToken() {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Convenience

    /// True if a token is present in Keychain
    static var isLoggedIn: Bool { token != nil }
}
