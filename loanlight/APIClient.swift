//
//  APIClient.swift
//  loanlight
//
//  Central HTTP client. All requests go through here.
//  Base URL is read from Info.plist (set via xcconfig).
//

import Foundation

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case noToken
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:               return "Invalid URL."
        case .noToken:                  return "Not logged in. Please sign in again."
        case .httpError(let code, let msg):
            return msg ?? "Server error (\(code))."
        case .decodingError(let e):     return "Could not parse response: \(e.localizedDescription)"
        case .unknown(let e):           return e.localizedDescription
        }
    }
}

// MARK: - APIClient

final class APIClient {

    static let shared = APIClient()

    // ── Base URL ─────────────────────────────────────────────
    // Set API_BASE_URL in Secrets.xcconfig or Info.plist.
    // Fallback to localhost for development.
    private let baseURL: String = {
        return "https://deck-ordering-presidential-awards.trycloudflare.com"
    }()

    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        session = URLSession.shared

        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys  // models handle snake_case via CodingKeys

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys  // models handle snake_case via CodingKeys

        // Parse ISO-8601 dates from backend (e.g. freedom_date: "2031-04-01")
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            // Try full ISO8601 first
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
            if let date = iso.date(from: str) { return date }
            // Try date-only (freedom_date format)
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "en_US_POSIX")
            if let date = df.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot parse date: \(str)")
        }
    }

    // MARK: - Core request methods

    func post<Body: Encodable, Response: Decodable>(
        _ path: String,
        body: Body,
        authenticated: Bool = true
    ) async throws -> Response {
        let request = try buildRequest(path: path, method: "POST", body: body, authenticated: authenticated)
        return try await execute(request)
    }

    func get<Response: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        let request = try buildRequest(path: path, method: "GET", queryItems: queryItems, authenticated: true)
        return try await execute(request)
    }

    // MARK: - Request builder

    private func buildRequest<Body: Encodable>(
        path: String,
        method: String,
        body: Body? = nil as String?,
        queryItems: [URLQueryItem] = [],
        authenticated: Bool
    ) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        if authenticated {
            guard let token = TokenStore.load() else { throw APIError.noToken }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body, method != "GET" {
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    // MARK: - Execute

    private func execute<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.unknown(error)
        }

        if let http = response as? HTTPURLResponse {
            guard (200...299).contains(http.statusCode) else {
                // Try to extract error detail from FastAPI response body
                let message = (try? JSONDecoder().decode(FastAPIError.self, from: data))?.detail
                throw APIError.httpError(statusCode: http.statusCode, message: message)
            }
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - FastAPI error shape

private struct FastAPIError: Decodable {
    let detail: String?
}
