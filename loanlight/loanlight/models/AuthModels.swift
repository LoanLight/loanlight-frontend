//
//  AuthModels.swift
//  loanlight
//

import Foundation

// MARK: - Requests

struct SignupRequest: Encodable {
    let email: String
    let password: String
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

// MARK: - Responses

struct TokenResponse: Decodable {
    let accessToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType   = "token_type"
    }
}

struct ProfileCompleteResponse: Decodable {
    let complete: Bool
    let missing: [String]
    let message: String?
}

struct AccountResponse: Decodable, Identifiable {
    let id: UUID
    let email: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}
