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
}
