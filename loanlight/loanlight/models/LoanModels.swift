import Foundation

// MARK: - Federal Loans
// Maps to: federal_loan_models.py

struct FederalLoanIn: Encodable {
    let loanName: String
    let balance: Decimal
    let interestRate: Decimal          // e.g. 6.8 means 6.8%
    let minMonthlyPayment: Decimal?

    enum CodingKeys: String, CodingKey {
        case loanName         = "loan_name"
        case balance
        case interestRate     = "interest_rate"
        case minMonthlyPayment = "min_monthly_payment"
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
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(UUID.self, forKey: .id)
        loanName       = try c.decode(String.self, forKey: .loanName)
        balance        = try Self.decimalFromString(c, key: .balance)
        interestRate   = try Self.decimalFromString(c, key: .interestRate)
        let pmtStr     = try c.decodeIfPresent(String.self, forKey: .minMonthlyPayment)
        minMonthlyPayment = pmtStr.flatMap { Decimal(string: $0) }
    }

    private static func decimalFromString(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Decimal {
        if let str = try? c.decode(String.self, forKey: key), let d = Decimal(string: str) { return d }
        return try c.decode(Decimal.self, forKey: key)
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
        let c        = try decoder.container(keyedBy: CodingKeys.self)
        loans        = try c.decode([FederalLoanOut].self, forKey: .loans)
        let tbStr    = try? c.decode(String.self, forKey: .totalBalance)
        totalBalance = try tbStr.flatMap { Decimal(string: $0) } ?? (try c.decode(Decimal.self, forKey: .totalBalance))
        let tmpStr   = try? c.decode(String.self, forKey: .totalMinPayment)
        totalMinPayment = try tmpStr.flatMap { Decimal(string: $0) } ?? (try c.decode(Decimal.self, forKey: .totalMinPayment))
    }
}

// MARK: - Private Loans
// Maps to: private_loan_models.py

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
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self, forKey: .id)
        lenderName   = try c.decode(String.self, forKey: .lenderName)
        currentBalance   = Self.decodeDecimal(c, key: .currentBalance)
        interestRate     = Self.decodeDecimal(c, key: .interestRate)
        minMonthlyPayment = Self.decodeDecimal(c, key: .minMonthlyPayment)
    }

    private static func decodeDecimal(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Decimal {
        if let str = try? c.decode(String.self, forKey: key), let d = Decimal(string: str) { return d }
        return (try? c.decode(Decimal.self, forKey: key)) ?? 0
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
        let c        = try decoder.container(keyedBy: CodingKeys.self)
        loans        = try c.decode([PrivateLoanOut].self, forKey: .loans)
        let tbStr    = try? c.decode(String.self, forKey: .totalBalance)
        totalBalance = try tbStr.flatMap { Decimal(string: $0) } ?? (try c.decode(Decimal.self, forKey: .totalBalance))
        let tmpStr   = try? c.decode(String.self, forKey: .totalMinPayment)
        totalMinPayment = try tmpStr.flatMap { Decimal(string: $0) } ?? (try c.decode(Decimal.self, forKey: .totalMinPayment))
    }
}
