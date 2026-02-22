//
//  TokenStore.swift
//  loanlight
//

import Foundation

/// Persists and provides the auth access token for API requests.
enum TokenStore {
    private static let key = "loanlight.accessToken"

    static var accessToken: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static func save(_ token: String) {
        accessToken = token
    }

    static func clear() {
        accessToken = nil
    }

    static var isLoggedIn: Bool {
        accessToken != nil
    }
}
