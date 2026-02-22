import Foundation

// MARK: - Enums
// Maps to: plan_models.py literals

enum RepaymentStrategy: String, Codable, CaseIterable, Identifiable {
    case avalanche
    case snowball
    case hybrid

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .avalanche: return "Avalanche"
        case .snowball:  return "Snowball"
        case .hybrid:    return "Hybrid"
        }
    }

    var subtitle: String {
        switch self {
        case .avalanche: return "Highest interest first · saves the most money"
        case .snowball:  return "Smallest balance first · quick wins"
        case .hybrid:    return "Mix of both approaches"
        }
    }
}

enum RiskLevel: String, Codable, CaseIterable, Identifiable {
    case low
    case moderate
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low:      return "Low"
        case .moderate: return "Moderate"
        case .high:     return "High"
        }
    }

    var expectedReturnLabel: String {
        switch self {
        case .low:      return "~4% avg return"
        case .moderate: return "~7% avg return"
        case .high:     return "~10% avg return"
        }
    }
}

enum BudgetSource: String, Codable {
    case slider
    case plaid
    case csv
}

// MARK: - Plan Request
// Maps to: PlanCalculateRequest in plan_models.py

struct BudgetInputs: Encodable {
    let monthlyNonHousingEssentials: Decimal
    let monthlyCommitment: Decimal          // the slider value the user picks
    let source: BudgetSource

    enum CodingKeys: String, CodingKey {
        case monthlyNonHousingEssentials = "monthly_non_housing_essentials"
        case monthlyCommitment           = "monthly_commitment"
        case source
    }
}

struct PlanCalculateRequest: Encodable {
    let repaymentStrategy: RepaymentStrategy
    let riskLevel: RiskLevel
    let investingEnabled: Bool
    let budgetInputs: BudgetInputs

    enum CodingKeys: String, CodingKey {
        case repaymentStrategy = "repayment_strategy"
        case riskLevel         = "risk_level"
        case investingEnabled  = "investing_enabled"
        case budgetInputs      = "budget_inputs"
    }
}

// MARK: - Plan Response
// Maps to: PlanCalculateResponse in plan_models.py

struct LimitsOut: Decodable {
    /// Minimum the slider can go (sum of all min monthly payments)
    let minCommitment: Decimal
    /// Maximum the slider can go (take home - rent - essentials)
    let maxCommitment: Decimal

    enum CodingKeys: String, CodingKey {
        case minCommitment = "min_commitment"
        case maxCommitment = "max_commitment"
    }
}

struct CashflowOut: Decodable {
    let takeHomeMonthly: Decimal
    let rentMonthly: Decimal
    let nonRentEssentials: Decimal
    let discretionaryBeforeLoans: Decimal
    let minimumLoanPayments: Decimal
    let monthlyCommitment: Decimal
    let extraAboveMinimum: Decimal
    let discretionaryLeft: Decimal

    enum CodingKeys: String, CodingKey {
        case takeHomeMonthly          = "take_home_monthly"
        case rentMonthly              = "rent_monthly"
        case nonRentEssentials        = "non_rent_essentials"
        case discretionaryBeforeLoans = "discretionary_before_loans"
        case minimumLoanPayments      = "minimum_loan_payments"
        case monthlyCommitment        = "monthly_commitment"
        case extraAboveMinimum        = "extra_above_minimum"
        case discretionaryLeft        = "discretionary_left"
    }
}

struct InvestingOut: Decodable {
    let enabled: Bool
    let riskLevel: RiskLevel
    let expectedReturnAnnual: Decimal
    let monthlyInvestment: Decimal
    let projectedInvestmentValueAtFreedom: Decimal

    enum CodingKeys: String, CodingKey {
        case enabled
        case riskLevel                         = "risk_level"
        case expectedReturnAnnual              = "expected_return_annual"
        case monthlyInvestment                 = "monthly_investment"
        case projectedInvestmentValueAtFreedom = "projected_investment_value_at_freedom"
    }
}

/// One data point in the month-by-month projection series
struct SeriesPoint: Decodable, Identifiable {
    var id: Int { monthIndex }
    let monthIndex: Int
    let date: Date
    let remainingLoanBalance: Decimal
    let paidPct: Decimal               // 0.0–1.0, useful for progress display
    let investmentBalance: Decimal

    enum CodingKeys: String, CodingKey {
        case monthIndex            = "month_index"
        case date
        case remainingLoanBalance  = "remaining_loan_balance"
        case paidPct               = "paid_pct"
        case investmentBalance     = "investment_balance"
    }
}

struct PlanCalculateResponse: Decodable {
    let freedomDate: Date
    let monthsToFreedom: Int
    let limits: LimitsOut
    let cashflow: CashflowOut
    let totalStartingDebt: Decimal
    let totalInterestPaid: Decimal
    let investing: InvestingOut
    let series: [SeriesPoint]
    let warnings: [String]

    enum CodingKeys: String, CodingKey {
        case freedomDate       = "freedom_date"
        case monthsToFreedom   = "months_to_freedom"
        case limits
        case cashflow
        case totalStartingDebt = "total_starting_debt"
        case totalInterestPaid = "total_interest_paid"
        case investing
        case series
        case warnings
    }
}
