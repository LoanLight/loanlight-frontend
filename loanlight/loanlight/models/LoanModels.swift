import Foundation

// MARK: - DecimalString helpers (for DECODING responses)
// The backend sends all Decimal fields as JSON strings ("18750.00").
// These helpers decode both string and number forms.

extension KeyedDecodingContainer {
    func decodeDecimalString(forKey key: Key) throws -> Decimal {
        if let str = try? decode(String.self, forKey: key) {
            let clean = str.trimmingCharacters(in: .whitespaces)
            if let d = Decimal(string: clean) { return d }
        }
        let dbl = try decode(Double.self, forKey: key)
        return Decimal(dbl)
    }

    func decodeDecimalStringIfPresent(forKey key: Key) throws -> Decimal? {
        guard contains(key) else { return nil }
        if let str = try? decode(String.self, forKey: key) {
            let clean = str.trimmingCharacters(in: .whitespaces)
            if clean.isEmpty || clean == "null" { return nil }
            return Decimal(string: clean)
        }
        if let dbl = try? decode(Double.self, forKey: key) { return Decimal(dbl) }
        return nil
    }
}

// MARK: - Federal Loans

// Request: API expects balance/interest_rate/min_monthly_payment as JSON numbers
struct FederalLoanIn: Encodable {
    let loanName: String
    let balance: Decimal
    let interestRate: Decimal
    let minMonthlyPayment: Decimal?

    enum CodingKeys: String, CodingKey {
        case loanName          = "loan_name"
        case balance
        case interestRate      = "interest_rate"
        case minMonthlyPayment = "min_monthly_payment"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(loanName, forKey: .loanName)
        try c.encode(NSDecimalNumber(decimal: balance).doubleValue, forKey: .balance)
        try c.encode(NSDecimalNumber(decimal: interestRate).doubleValue, forKey: .interestRate)
        if let p = minMonthlyPayment {
            try c.encode(NSDecimalNumber(decimal: p).doubleValue, forKey: .minMonthlyPayment)
        }
    }
}

struct FederalLoanOut: Decodable, Identifiable {
    let id: UUID
    let loanName: String
    let balance: Decimal
    let interestRate: Decimal
    let minMonthlyPayment: Decimal?

    enum CodingKeys: String, CodingKey {
        case id
        case loanName          = "loan_name"
        case balance
        case interestRate      = "interest_rate"
        case minMonthlyPayment = "min_monthly_payment"
    }

    init(from decoder: Decoder) throws {
        let c        = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self, forKey: .id)
        loanName     = try c.decode(String.self, forKey: .loanName)
        balance      = try c.decodeDecimalString(forKey: .balance)
        interestRate = try c.decodeDecimalString(forKey: .interestRate)
        minMonthlyPayment = try c.decodeDecimalStringIfPresent(forKey: .minMonthlyPayment)
    }
}

struct FederalLoanBulkIn: Encodable {
    let loans: [FederalLoanIn]
}

struct FederalLoanBulkOut: Decodable {
    let loans: [FederalLoanOut]
    let totalBalance: Decimal
    let totalMinPayment: Decimal

    enum CodingKeys: String, CodingKey {
        case loans
        case totalBalance    = "total_balance"
        case totalMinPayment = "total_min_payment"
    }

    init(from decoder: Decoder) throws {
        let c           = try decoder.container(keyedBy: CodingKeys.self)
        loans           = try c.decode([FederalLoanOut].self, forKey: .loans)
        totalBalance    = try c.decodeDecimalString(forKey: .totalBalance)
        totalMinPayment = try c.decodeDecimalString(forKey: .totalMinPayment)
    }
}

// MARK: - Private Loans

struct PrivateLoanIn: Encodable {
    let lenderName: String
    let currentBalance: Decimal
    let interestRate: Decimal
    let minMonthlyPayment: Decimal

    enum CodingKeys: String, CodingKey {
        case lenderName        = "lender_name"
        case currentBalance    = "current_balance"
        case interestRate      = "interest_rate"
        case minMonthlyPayment = "min_monthly_payment"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(lenderName, forKey: .lenderName)
        try c.encode(NSDecimalNumber(decimal: currentBalance).doubleValue, forKey: .currentBalance)
        try c.encode(NSDecimalNumber(decimal: interestRate).doubleValue, forKey: .interestRate)
        try c.encode(NSDecimalNumber(decimal: minMonthlyPayment).doubleValue, forKey: .minMonthlyPayment)
    }
}

struct PrivateLoanOut: Decodable, Identifiable {
    let id: UUID
    let lenderName: String
    let currentBalance: Decimal
    let interestRate: Decimal
    let minMonthlyPayment: Decimal

    enum CodingKeys: String, CodingKey {
        case id
        case lenderName        = "lender_name"
        case currentBalance    = "current_balance"
        case interestRate      = "interest_rate"
        case minMonthlyPayment = "min_monthly_payment"
    }

    init(from decoder: Decoder) throws {
        let c             = try decoder.container(keyedBy: CodingKeys.self)
        id                = try c.decode(UUID.self, forKey: .id)
        lenderName        = try c.decode(String.self, forKey: .lenderName)
        currentBalance    = try c.decodeDecimalString(forKey: .currentBalance)
        interestRate      = try c.decodeDecimalString(forKey: .interestRate)
        minMonthlyPayment = try c.decodeDecimalString(forKey: .minMonthlyPayment)
    }
}

struct PrivateLoanBulkIn: Encodable {
    let loans: [PrivateLoanIn]
}

struct PrivateLoanBulkOut: Decodable {
    let loans: [PrivateLoanOut]
    let totalBalance: Decimal
    let totalMinPayment: Decimal

    enum CodingKeys: String, CodingKey {
        case loans
        case totalBalance    = "total_balance"
        case totalMinPayment = "total_min_payment"
    }

    init(from decoder: Decoder) throws {
        let c           = try decoder.container(keyedBy: CodingKeys.self)
        loans           = try c.decode([PrivateLoanOut].self, forKey: .loans)
        totalBalance    = try c.decodeDecimalString(forKey: .totalBalance)
        totalMinPayment = try c.decodeDecimalString(forKey: .totalMinPayment)
    }
}
