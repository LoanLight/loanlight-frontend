import Foundation
import Combine

// MARK: - PlanViewModel
//
// This is the single source of truth for the Plan screen.
// It holds all user inputs (sliders, toggles) and the latest
// response from /plan/calculate. The View just reads from this.

@MainActor
final class PlanViewModel: ObservableObject {

    // ── Inputs from prior onboarding screens ──────────────────
    // Populated once when the screen loads; not edited here.
    var jobOffer: JobOfferOut?
    var housing: HousingOut?

    // ── User Inputs (drive the request) ───────────────────────

    /// How much the user wants to put toward loans (+ investing) per month.
    /// Clamped between limits.minCommitment and limits.maxCommitment.
    @Published var monthlyCommitment: Decimal = 0

    /// How much of the monthly commitment goes to investing.
    /// Only relevant when investingEnabled = true.
    /// Range: 0 ... (monthlyCommitment - cashflow.minimumLoanPayments)
    @Published var monthlyInvestmentAmount: Decimal = 0

    /// User's manually entered monthly non-housing expenses (food, transport, etc.)
    @Published var monthlyExpenses: Decimal = 0

    @Published var repaymentStrategy: RepaymentStrategy = .avalanche
    @Published var riskLevel: RiskLevel = .moderate
    @Published var investingEnabled: Bool = false

    // ── Response from backend ──────────────────────────────────
    @Published var planResponse: PlanCalculateResponse? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // ── Derived helpers for the UI ─────────────────────────────

    /// Total take-home minus rent minus expenses = what's available
    var availableForLoansAndInvesting: Decimal {
        guard let job = jobOffer, let housing = housing else { return 0 }
        return max(0, job.estimatedTakeHomeMonthly - housing.hudEstimatedRentMonthly - monthlyExpenses)
    }

    /// Slider lower bound — must cover all minimum payments
    var sliderMin: Decimal {
        planResponse?.limits.minCommitment ?? 0
    }

    /// Slider upper bound — everything left after rent + essentials
    var sliderMax: Decimal {
        planResponse?.limits.maxCommitment ?? availableForLoansAndInvesting
    }

    /// Max the user can choose to invest (commitment minus required loan minimums)
    var maxInvestmentAmount: Decimal {
        guard let cashflow = planResponse?.cashflow else { return 0 }
        return max(0, monthlyCommitment - cashflow.minimumLoanPayments)
    }

    /// Convenience: the series data ready for charting
    var chartSeries: [SeriesPoint] {
        planResponse?.series ?? []
    }

    /// Convenience: freedom date as a formatted string
    var freedomDateFormatted: String {
        guard let date = planResponse?.freedomDate else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }

    /// Total wealth at freedom = projected investment value (backend computes this)
    var totalWealthAtFreedom: Decimal {
        planResponse?.investing.projectedInvestmentValueAtFreedom ?? 0
    }

    // MARK: - Fetch / Recalculate

    func recalculate() async {
        guard jobOffer != nil, housing != nil else { return }

        isLoading = true
        errorMessage = nil

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
            // Replace with your actual API service call
            let response = try await PlanAPIService.shared.calculate(request)
            planResponse = response

            // Clamp commitment to valid range on first load
            if monthlyCommitment == 0 {
                monthlyCommitment = response.limits.minCommitment
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Placeholder API Service
// Replace the body of calculate() with your real URLSession / Alamofire call.

final class PlanAPIService {
    static let shared = PlanAPIService()
    private init() {}

    func calculate(_ request: PlanCalculateRequest) async throws -> PlanCalculateResponse {
        // TODO: wire up to POST /plan/calculate
        // Example shape:
        // let url = URL(string: "https://your-api.com/plan/calculate")!
        // var req = URLRequest(url: url)
        // req.httpMethod = "POST"
        // req.httpBody = try JSONEncoder().encode(request)
        // req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // let (data, _) = try await URLSession.shared.data(for: req)
        // return try JSONDecoder().decode(PlanCalculateResponse.self, from: data)
        fatalError("PlanAPIService.calculate() not yet implemented")
    }
}
