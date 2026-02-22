import Foundation
import Combine

// MARK: - PlanViewModel

@MainActor
final class PlanViewModel: ObservableObject {

    // ── Inputs from onboarding ─────────────────────────────────
    var jobOffer: JobOfferOut?
    var housing: HousingOut?

    // ── User inputs ────────────────────────────────────────────
    @Published var monthlyCommitment: Decimal = 0
    @Published var monthlyInvestmentAmount: Decimal = 0
    @Published var monthlyExpenses: Decimal = 0
    @Published var repaymentStrategy: RepaymentStrategy = .avalanche
    @Published var riskLevel: RiskLevel = .moderate
    @Published var investingEnabled: Bool = false

    // ── Response state ─────────────────────────────────────────
    @Published var planResponse: PlanCalculateResponse? = nil
    @Published var limitsResponse: PlanLimitsResponse? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // ── Derived helpers ────────────────────────────────────────

    var sliderMin: Decimal {
        limitsResponse?.limits.minCommitment
            ?? planResponse?.limits.minCommitment
            ?? 0
    }

    var sliderMax: Decimal {
        limitsResponse?.limits.maxCommitment
            ?? planResponse?.limits.maxCommitment
            ?? max(1, availableForLoansAndInvesting)
    }

    var availableForLoansAndInvesting: Decimal {
        guard let job = jobOffer, let housing = housing else { return 0 }
        return max(0, job.estimatedTakeHomeMonthly - housing.hudEstimatedRentMonthly - monthlyExpenses)
    }

    var maxInvestmentAmount: Decimal {
        guard let cashflow = planResponse?.cashflow else { return 0 }
        return max(0, monthlyCommitment - cashflow.minimumLoanPayments)
    }

    var chartSeries: [SeriesPoint] { planResponse?.series ?? [] }

    var freedomDateFormatted: String {
        guard let date = planResponse?.freedomDate else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }

    var totalWealthAtFreedom: Decimal {
        planResponse?.investing.projectedInvestmentValueAtFreedom ?? 0
    }

    // MARK: - Fetch limits (call when expenses change, before sliders are shown)

    /// Called on logout — wipes all cached state
    func reset() {
        planResponse    = nil
        limitsResponse  = nil
        jobOffer        = nil
        housing         = nil
        monthlyCommitment       = 0
        monthlyInvestmentAmount = 0
        monthlyExpenses         = 0
        investingEnabled        = true
        repaymentStrategy       = .avalanche
        riskLevel               = .moderate
        errorMessage            = nil
    }

    func fetchLimits() async {
        // Send as a plain number string — avoid "0.0" which confuses some backends
        let essentialsValue = monthlyExpenses > 0 ? monthlyExpenses : Decimal(900) // sensible default
        let essentialsStr = NSDecimalNumber(decimal: essentialsValue).stringValue
        let queryItems = [URLQueryItem(name: "monthly_non_housing_essentials", value: essentialsStr)]

        do {
            let response: PlanLimitsResponse = try await APIClient.get(
                path: "/plan/limits",
                queryItems: queryItems
            )
            limitsResponse = response

            // Initialize commitment to midpoint of range on first load
            if monthlyCommitment == 0 {
                let mid = (response.limits.minCommitment + response.limits.maxCommitment) / 2
                monthlyCommitment = mid
            }
        } catch {
            // Non-fatal — sliders will fall back to local estimates
            print("[PlanVM] fetchLimits error: \(error)")
        }
    }

    // MARK: - Recalculate (POST /plan/calculate)

    func recalculate() async {
        isLoading = true
        errorMessage = nil

        // Clamp commitment to valid range before sending
        if sliderMax > sliderMin {
            monthlyCommitment = max(sliderMin, min(sliderMax, monthlyCommitment))
        }

        let request = PlanCalculateRequest(
            repaymentStrategy: repaymentStrategy,
            riskLevel: riskLevel,
            investingEnabled: investingEnabled,
            budgetInputs: BudgetInputs(
                monthlyNonHousingEssentials: monthlyExpenses,
                monthlyCommitment: monthlyCommitment,
                source: .slider
            )
        )

        do {
            let response: PlanCalculateResponse = try await APIClient.post(
                path: "/plan/calculate",
                body: request
            )
            planResponse = response

            // Update limits from response (backend may have tighter bounds)
            if monthlyCommitment == 0 {
                monthlyCommitment = response.limits.minCommitment
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Could not calculate plan. Please try again."
        }

        isLoading = false
    }
}
