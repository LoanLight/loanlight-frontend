//
//  PlanViewModel.swift
//  loanlight
//

import Foundation
import Combine

@MainActor
final class PlanViewModel: ObservableObject {

    // ── Inputs from onboarding (set by AppCoordinator) ────────
    var jobOffer: JobOfferOut?
    var housing: HousingOut?

    // ── User Inputs ────────────────────────────────────────────
    @Published var monthlyCommitment: Decimal = 0
    @Published var monthlyInvestmentAmount: Decimal = 0
    @Published var monthlyExpenses: Decimal = 0
    @Published var repaymentStrategy: RepaymentStrategy = .avalanche
    @Published var riskLevel: RiskLevel = .moderate
    @Published var investingEnabled: Bool = false

    // ── Backend Response ───────────────────────────────────────
    @Published var planResponse: PlanCalculateResponse? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // ── Derived helpers ────────────────────────────────────────

    var availableForLoansAndInvesting: Decimal {
        guard let job = jobOffer, let housing = housing else { return 0 }
        return max(0, job.estimatedTakeHomeMonthly - housing.hudEstimatedRentMonthly - monthlyExpenses)
    }

    var sliderMin: Decimal { planResponse?.limits.minCommitment ?? 0 }
    var sliderMax: Decimal { planResponse?.limits.maxCommitment ?? availableForLoansAndInvesting }

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

    // MARK: - Recalculate → POST /plan/calculate

    private let baseURL = "https://deck-ordering-presidential-awards.trycloudflare.com"

    func recalculate() async {
        guard jobOffer != nil, housing != nil else { return }
        guard let token = TokenStore.load() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

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
            let url = URL(string: baseURL + "/plan/calculate")!
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            urlRequest.httpBody = try JSONEncoder().encode(request)

            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? ""
                print("⚠️ plan/calculate \(http.statusCode): \(body)")
                errorMessage = "Server error (\(http.statusCode))"
                return
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let str = try container.decode(String.self)
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                df.locale = Locale(identifier: "en_US_POSIX")
                if let date = df.date(from: str) { return date }
                let iso = ISO8601DateFormatter()
                if let date = iso.date(from: str) { return date }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot parse date: \(str)")
            }
            let planResponse = try decoder.decode(PlanCalculateResponse.self, from: data)
            self.planResponse = planResponse

            if monthlyCommitment == 0 {
                monthlyCommitment = planResponse.limits.minCommitment
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Reload existing profile (for returning users)
    //
    // Called when a user is already logged in and skips onboarding.
    // Fetches their saved job offer + housing from the backend,
    // then runs the plan calculation.

    func loadExistingProfile() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Fetch job offer
            let jobOut: JobOfferOut = try await APIClient.shared.get("/job-offer/current")
            self.jobOffer = jobOut

            // Fetch housing
            let housingOut: HousingOut = try await APIClient.shared.get("/housing/current")
            self.housing = housingOut

            // Run initial plan calculation
            await recalculate()

        } catch let error as APIError {
            switch error {
            case .httpError(let code, _) where code == 404:
                // Profile incomplete — this is fine, plan screen will show empty state
                break
            default:
                errorMessage = error.errorDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
