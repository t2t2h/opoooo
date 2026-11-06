// Store a user's WireGuard profile in Keychain (never in the injected dylib).
import Foundation
import Security

enum WireGuardProfileVault {
    private static let service = "com.aflatoonmubdi.wireguard.profile"
    private static let account = "active-profile"

    static func save(_ config: String) throws {
        guard !config.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "AflatoonWireGuard", code: 10,
                          userInfo: [NSLocalizedDescriptionKey: "Profile is empty"])
        }
        let data = Data(config.utf8)
        let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: service,
                                   kSecAttrAccount as String: account]
        let update = [kSecValueData as String: data,
                      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly] as [String: Any]
        let status = SecItemUpdate(base as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var add = base
            update.forEach { add[$0.key] = $0.value }
            let addStatus = SecItemAdd(add as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(addStatus)) }
        } else if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    static func load() throws -> String {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data,
              let config = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "AflatoonWireGuard", code: Int(status),
                          userInfo: [NSLocalizedDescriptionKey: "No saved WireGuard profile in Keychain"])
        }
        return config
    }
}
