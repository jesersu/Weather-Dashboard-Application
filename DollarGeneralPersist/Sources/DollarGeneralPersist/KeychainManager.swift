//
//  KeychainManager.swift
//  DollarGeneralPersist
//
//  Created by Claude Code
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import Security

public class KeychainManager {

    public init() {}

    /// Save attribute to Keychain
    ///
    /// - Parameters:
    ///   - key: Key for the attribute
    ///   - value: Value to save
    public static func saveAttribute(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Retrieve attribute from Keychain
    ///
    /// - Parameter key: Key for the attribute
    /// - Returns: Retrieved value as string, or nil if not found
    public static func retrieveAttribute(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    /// Modify existing attribute in Keychain
    ///
    /// - Parameters:
    ///   - key: Key for the attribute
    ///   - value: New value
    public static func modifyAttribute(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    }

    /// Delete attribute from Keychain
    ///
    /// - Parameter key: Key for the attribute to delete
    public static func deleteAttribute(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
