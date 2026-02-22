//
//  APIClient.swift
//  loanlight
//

import Foundation

/// Shared API client for the LoanLight backend.
/// Configure `baseURL` for simulator (localhost) or device (your machine's IP).
enum APIClient {

    static var baseURL: String = {
        #if targetEnvironment(simulator)
        return "https://deck-ordering-presidential-awards.trycloudflare.com"
        #else
        // On device, use your machine's IP and ensure backend allows that host
        return "https://deck-ordering-presidential-awards.trycloudflare.com"
        #endif
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    /// POST JSON body to path and decode response as T.
    /// Set `authenticated: false` for auth routes (login/signup) so no Bearer token is sent.
    static func post<T: Decodable, B: Encodable>(path: String, body: B, authenticated: Bool = true) async throws -> T {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)

        if authenticated, let token = TokenStore.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if http.statusCode == 401 {
            throw APIError.unauthorized
        }
        if http.statusCode == 422 {
            throw APIError.validationError
        }
        if http.statusCode < 200 || http.statusCode >= 300 {
            let message = (try? decoder.decode(ErrorBody.self, from: data))?.detail ?? "Request failed"
            throw APIError.serverError(statusCode: http.statusCode, message: message)
        }

        return try decoder.decode(T.self, from: data)
    }

    /// GET path and decode response as T. Adds Bearer token if available.
    static func get<T: Decodable>(path: String) async throws -> T {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = TokenStore.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if http.statusCode == 401 {
            throw APIError.unauthorized
        }
        if http.statusCode < 200 || http.statusCode >= 300 {
            let message = (try? decoder.decode(ErrorBody.self, from: data))?.detail ?? "Request failed"
            throw APIError.serverError(statusCode: http.statusCode, message: message)
        }

        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Error handling

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case validationError
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server."
        case .unauthorized: return "Invalid email or password."
        case .validationError: return "Invalid input. Please check your details."
        case .serverError(_, let message): return message
        }
    }
}

/// Backend may return {"detail": "string"} or {"detail": [{"msg": "..."}]}.
private struct ErrorBody: Decodable {
    let detail: String?
    enum CodingKeys: String, CodingKey { case detail }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decode(String.self, forKey: .detail) {
            detail = s
        } else if let arr = try? c.decode([ValidationItem].self, forKey: .detail), let first = arr.first?.msg {
            detail = first
        } else {
            detail = nil
        }
    }
    private struct ValidationItem: Decodable { let msg: String? }
}
