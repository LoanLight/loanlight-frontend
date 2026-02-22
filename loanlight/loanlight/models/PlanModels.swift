import Foundation

// MARK: - Enums

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

// MARK: - Plan Limits Response (GET /plan/limits)

struct PlanLimitsResponse: Decodable {
    let takeHomeMonthly: Decimal
    let rentMonthly: Decimal
    let minimumLoanPayments: Decimal
    let monthlyNonHousingEssentials: Decimal
    let discretionaryBeforeLoans: Decimal
    let afterMinPayments: Decimal
    let limits: LimitsOut
    let warnings: [String]

    enum CodingKeys: String, CodingKey {
        case takeHomeMonthly             = "take_home_monthly"
        case rentMonthly                 = "rent_monthly"
        case minimumLoanPayments         = "minimum_loan_payments"
        case monthlyNonHousingEssentials = "monthly_non_housing_essentials"
        case discretionaryBeforeLoans    = "discretionary_before_loans"
        case afterMinPayments            = "after_min_payments"
        case limits
        case warnings
    }

    init(from decoder: Decoder) throws {
        let c                        = try decoder.container(keyedBy: CodingKeys.self)
        takeHomeMonthly              = try c.decodeDecimalString(forKey: .takeHomeMonthly)
        rentMonthly                  = try c.decodeDecimalString(forKey: .rentMonthly)
        minimumLoanPayments          = try c.decodeDecimalString(forKey: .minimumLoanPayments)
        monthlyNonHousingEssentials  = try c.decodeDecimalString(forKey: .monthlyNonHousingEssentials)
        discretionaryBeforeLoans     = try c.decodeDecimalString(forKey: .discretionaryBeforeLoans)
        afterMinPayments             = try c.decodeDecimalString(forKey: .afterMinPayments)
        limits                       = try c.decode(LimitsOut.self, forKey: .limits)
        warnings                     = try c.decode([String].self, forKey: .warnings)
    }
}

// MARK: - Plan Request

struct BudgetInputs: Encodable {
    let monthlyNonHousingEssentials: Decimal
    let monthlyCommitment: Decimal
    let source: BudgetSource

    enum CodingKeys: String, CodingKey {
        case monthlyNonHousingEssentials = "monthly_non_housing_essentials"
        case monthlyCommitment           = "monthly_commitment"
        case source
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        // API expects numbers, not strings
        try c.encode(NSDecimalNumber(decimal: monthlyNonHousingEssentials).doubleValue,
                     forKey: .monthlyNonHousingEssentials)
        try c.encode(NSDecimalNumber(decimal: monthlyCommitment).doubleValue,
                     forKey: .monthlyCommitment)
        try c.encode(source, forKey: .source)
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

struct LimitsOut: Decodable {
    let minCommitment: Decimal
    let maxCommitment: Decimal

    enum CodingKeys: String, CodingKey {
        case minCommitment = "min_commitment"
        case maxCommitment = "max_commitment"
    }

    init(from decoder: Decoder) throws {
        let c         = try decoder.container(keyedBy: CodingKeys.self)
        minCommitment = try c.decodeDecimalString(forKey: .minCommitment)
        maxCommitment = try c.decodeDecimalString(forKey: .maxCommitment)
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

    init(from decoder: Decoder) throws {
        let c                    = try decoder.container(keyedBy: CodingKeys.self)
        takeHomeMonthly          = try c.decodeDecimalString(forKey: .takeHomeMonthly)
        rentMonthly              = try c.decodeDecimalString(forKey: .rentMonthly)
        nonRentEssentials        = try c.decodeDecimalString(forKey: .nonRentEssentials)
        discretionaryBeforeLoans = try c.decodeDecimalString(forKey: .discretionaryBeforeLoans)
        minimumLoanPayments      = try c.decodeDecimalString(forKey: .minimumLoanPayments)
        monthlyCommitment        = try c.decodeDecimalString(forKey: .monthlyCommitment)
        extraAboveMinimum        = try c.decodeDecimalString(forKey: .extraAboveMinimum)
        discretionaryLeft        = try c.decodeDecimalString(forKey: .discretionaryLeft)
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

    init(from decoder: Decoder) throws {
        let c                              = try decoder.container(keyedBy: CodingKeys.self)
        enabled                            = try c.decode(Bool.self, forKey: .enabled)
        riskLevel                          = try c.decode(RiskLevel.self, forKey: .riskLevel)
        expectedReturnAnnual               = try c.decodeDecimalString(forKey: .expectedReturnAnnual)
        monthlyInvestment                  = try c.decodeDecimalString(forKey: .monthlyInvestment)
        projectedInvestmentValueAtFreedom  = try c.decodeDecimalString(forKey: .projectedInvestmentValueAtFreedom)
    }
}

struct SeriesPoint: Decodable, Identifiable {
    var id: Int { monthIndex }
    let monthIndex: Int
    let date: Date
    let remainingLoanBalance: Decimal
    let paidPct: Decimal
    let investmentBalance: Decimal

    enum CodingKeys: String, CodingKey {
        case monthIndex           = "month_index"
        case date
        case remainingLoanBalance = "remaining_loan_balance"
        case paidPct              = "paid_pct"
        case investmentBalance    = "investment_balance"
    }

    init(from decoder: Decoder) throws {
        let c                 = try decoder.container(keyedBy: CodingKeys.self)
        monthIndex            = try c.decode(Int.self, forKey: .monthIndex)
        date                  = try c.decode(Date.self, forKey: .date)
        remainingLoanBalance  = try c.decodeDecimalString(forKey: .remainingLoanBalance)
        paidPct               = try c.decodeDecimalString(forKey: .paidPct)
        investmentBalance     = try c.decodeDecimalString(forKey: .investmentBalance)
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

    init(from decoder: Decoder) throws {
        let c              = try decoder.container(keyedBy: CodingKeys.self)
        freedomDate        = try c.decode(Date.self, forKey: .freedomDate)
        monthsToFreedom    = try c.decode(Int.self, forKey: .monthsToFreedom)
        limits             = try c.decode(LimitsOut.self, forKey: .limits)
        cashflow           = try c.decode(CashflowOut.self, forKey: .cashflow)
        totalStartingDebt  = try c.decodeDecimalString(forKey: .totalStartingDebt)
        totalInterestPaid  = try c.decodeDecimalString(forKey: .totalInterestPaid)
        investing          = try c.decode(InvestingOut.self, forKey: .investing)
        series             = try c.decode([SeriesPoint].self, forKey: .series)
        warnings           = try c.decode([String].self, forKey: .warnings)
    }
}
