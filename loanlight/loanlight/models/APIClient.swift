import Foundation

// MARK: - API Configuration

enum APIConfig {
    static let baseURL = "https://deck-ordering-presidential-awards.trycloudflare.com"
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case noToken
    case httpError(Int, String?)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid URL."
        case .noToken:              return "Not authenticated. Please sign in."
        case .httpError(let code, let msg):
            if let msg { return "Server error (\(code)): \(msg)" }
            return "Server error (\(code))."
        case .decodingError(let e): return "Unexpected response format: \(e.localizedDescription)"
        case .networkError(let e):  return e.localizedDescription
        }
    }
}

// MARK: - APIClient

enum APIClient {

    // MARK: - Decoder (shared, configured correctly)

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        // NO global .convertFromSnakeCase — all models use explicit CodingKeys

        // Date strategy: handles ISO8601 with/without fractional seconds,
        // AND date-only strings like "2031-02-01"
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)

            // 1. Try date-only: "2031-02-01"
            let dateOnlyFmt = DateFormatter()
            dateOnlyFmt.dateFormat = "yyyy-MM-dd"
            dateOnlyFmt.locale = Locale(identifier: "en_US_POSIX")
            dateOnlyFmt.timeZone = TimeZone(secondsFromGMT: 0)
            if let d = dateOnlyFmt.date(from: str) { return d }

            // 2. Try ISO8601 with fractional seconds
            let isoFrac = ISO8601DateFormatter()
            isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = isoFrac.date(from: str) { return d }

            // 3. Try ISO8601 without fractional seconds
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let d = iso.date(from: str) { return d }

            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "Cannot decode date: \(str)")
        }

        // Decimal strategy: backend sends Decimal fields as JSON strings ("18750.00")
        // but sometimes as numbers. We handle both via a custom decode on all models,
        // but the real safety net is using Decimal(string:) via CodingKeys in models.
        // Note: Swift's JSONDecoder decodes Decimal from JSON strings natively —
        // if the backend sends a number literal we need to intercept it.
        d.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )
        return d
    }()

    // MARK: - Encoder

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        // NO global .convertToSnakeCase — all models use explicit CodingKeys
        // Decimals must encode as JSON numbers (not strings) — the API expects numbers
        return e
    }()

    // Swift's JSONEncoder encodes Decimal as a string by default.
    // The API expects numbers. This wrapper forces Decimal → JSON number.
    // Usage: replace `Decimal` fields in Encodable request models with `DecimalNumber`.
    struct DecimalNumber: Encodable {
        let value: Decimal
        func encode(to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            // Encode as a Double — preserves enough precision for currency values
            let d = NSDecimalNumber(decimal: value).doubleValue
            try c.encode(d)
        }
    }


    // MARK: - GET

    static func get<T: Decodable>(path: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        var components = URLComponents(string: APIConfig.baseURL + path)!
        components.queryItems = queryItems

        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "GET"
        try injectAuthHeader(&request)

        #if DEBUG
        print("[APIClient] GET \(path)")
        #endif

        return try await perform(request)
    }

    // MARK: - POST

    static func post<B: Encodable, T: Decodable>(path: String, body: B) async throws -> T {
        guard let url = URL(string: APIConfig.baseURL + path) else { throw APIError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        try injectAuthHeader(&request)

        #if DEBUG
        if let body = request.httpBody, let str = String(data: body, encoding: .utf8) {
            print("[APIClient] POST \(path) body: \(str)")
        }
        #endif

        return try await perform(request)
    }

    // MARK: - Error body helper (must be outside generic function)

    private struct APIErrorBody: Decodable {
        let detail: String?

        // Handles both string detail and array-of-validation-errors
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            if let str = try? c.decode(String.self, forKey: .detail) {
                detail = str
            } else if let arr = try? c.decode([ValidationMsg].self, forKey: .detail) {
                detail = arr.first?.msg
            } else {
                detail = nil
            }
        }
        enum CodingKeys: String, CodingKey { case detail }
        struct ValidationMsg: Decodable { let msg: String }
    }

    // MARK: - Core perform

    private static func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw APIError.httpError(0, nil)
            }

            #if DEBUG
            if let str = String(data: data, encoding: .utf8) {
                print("[APIClient] Response \(http.statusCode): \(str.prefix(500))")
            }
            #endif

            guard (200...299).contains(http.statusCode) else {
                let msg = (try? JSONDecoder().decode(APIErrorBody.self, from: data))?.detail
                throw APIError.httpError(http.statusCode, msg)
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                #if DEBUG
                print("[APIClient] DECODE ERROR for \(T.self): \(error)")
                if let str = String(data: data, encoding: .utf8) {
                    print("[APIClient] Raw response was: \(str)")
                }
                #endif
                throw APIError.decodingError(error)
            }
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Auth header

    private static func injectAuthHeader(_ request: inout URLRequest) throws {
        // Public endpoints don't need auth
        let publicPaths = ["/auth/signup", "/auth/login", "/health"]
        let path = request.url?.path ?? ""
        if publicPaths.contains(path) { return }

        guard let token = TokenStore.token else {
            throw APIError.noToken
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}
