//
//  AppCoordinator.swift
//  loanlight
//

import SwiftUI

// MARK: - Screen Enum

enum AppScreen {
    case auth
    case onboarding(OnboardingStep)
    case main
}

enum OnboardingStep {
    case federalLoans          // Step 1 — upload PDF
    case confirmFederalLoans   // Step 2 — review federal loan
    case privateLoans          // Step 3 — upload all private loans
    case confirmPrivateLoans   // Step 4 — review all private loans
    case offerLetter           // Step 5
    case location              // Step 6
    case loading               // Step 7
}

// MARK: - Onboarding State

private final class OnboardingState {
    var confirmedFederalLoans: [LoanEntity]  = []
    var pendingPrivateLoans: [LoanEntity]    = []
    var privateLoans: [PrivateLoanIn]        = []
    var jobOffer: JobOfferIn?                = nil
    var housing: HousingIn?                  = nil
    var monthlyExpenses: Double              = 0
}

// MARK: - AppCoordinator

struct AppCoordinator: View {
    @State private var screen: AppScreen = .auth
    @State private var onboardingState = OnboardingState()
    @StateObject private var planVM = PlanViewModel()

    var body: some View {
        Group {
            switch screen {
            case .auth:
                AuthFlowView(onAuthenticated: {
                    transition(to: .onboarding(.federalLoans))
                })
            case .onboarding(let step):
                onboardingView(for: step)
            case .main:
                MainTabView(planVM: planVM)
            }
        }
    }

    // MARK: - Onboarding Step Views

    @ViewBuilder
    private func onboardingView(for step: OnboardingStep) -> some View {
        switch step {

        case .federalLoans:
            FederalLoansView(currentStep: 1, totalSteps: 7, onComplete: { extractedLoans in
                onboardingState.confirmedFederalLoans = extractedLoans
                transition(to: .onboarding(.confirmFederalLoans))
            })

        case .confirmFederalLoans:
            LoanConfirmationView(
                loan: onboardingState.confirmedFederalLoans.first ?? LoanEntity(),
                onSave: { savedLoan in
                    onboardingState.confirmedFederalLoans = [savedLoan]
                    transition(to: .onboarding(.privateLoans))
                }
            )

        case .privateLoans:
            PrivateLoanView(
                currentStep: 3,
                totalSteps: 7,
                onContinue: { loanEntities in
                    if loanEntities.isEmpty {
                        onboardingState.privateLoans = []
                        transition(to: .onboarding(.offerLetter))
                    } else {
                        onboardingState.pendingPrivateLoans = loanEntities
                        transition(to: .onboarding(.confirmPrivateLoans))
                    }
                }
            )

        case .confirmPrivateLoans:
            PrivateLoansConfirmationView(
                loans: onboardingState.pendingPrivateLoans,
                onSave: { savedLoans in
                    onboardingState.privateLoans = savedLoans.map { entity in
                        PrivateLoanIn(
                            lenderName: entity.servicer.isEmpty ? "Private Loan" : entity.servicer,
                            currentBalance: Decimal(string: entity.totalBalance
                                .replacingOccurrences(of: "$", with: "")
                                .replacingOccurrences(of: ",", with: "")) ?? 0,
                            interestRate: Decimal(string: entity.interestRate
                                .replacingOccurrences(of: "%", with: "")) ?? 0,
                            minMonthlyPayment: Decimal(string: entity.monthlyPayment
                                .replacingOccurrences(of: "$", with: "")
                                .replacingOccurrences(of: ",", with: "")) ?? 0
                        )
                    }
                    transition(to: .onboarding(.offerLetter))
                }
            )

        case .offerLetter:
            OfferLetterView(currentStep: 5, totalSteps: 7, onContinue: { jobOfferIn in
                onboardingState.jobOffer = jobOfferIn
                transition(to: .onboarding(.location))
            })

        case .location:
            LocationView(currentStep: 6, totalSteps: 7, onContinue: { housingIn, expenses in
                onboardingState.housing = housingIn
                onboardingState.monthlyExpenses = expenses
                transition(to: .onboarding(.loading))
            })

        case .loading:
            PlanLoadingView {
                Task {
                    await submitOnboardingData()
                }
            }
        }
    }

    // MARK: - Backend Base URL
    // Replace with your deployed backend URL — no trailing slash.
    private let baseURL = "https://deck-ordering-presidential-awards.trycloudflare.com"

    // MARK: - Submit All Onboarding Data to Backend

    private func submitOnboardingData() async {
        guard let token = TokenStore.load() else {
            print("⚠️ No token found")
            transition(to: .main)
            return
        }

        let encoder = JSONEncoder()
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

        func post<Body: Encodable, Response: Decodable>(
            path: String,
            body: Body,
            as type: Response.Type
        ) async throws -> Response {
            let url = URL(string: baseURL + path)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = try encoder.encode(body)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? "no body"
                print("⚠️ \(http.statusCode) from \(path): \(body)")
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "Server error (\(http.statusCode))"])
            }
            return try decoder.decode(Response.self, from: data)
        }

        do {
            // 1. POST /federal-loans/bulk
            let federalPayload = FederalLoanBulkIn(
                loans: onboardingState.confirmedFederalLoans.map { $0.toFederalLoanIn() }
            )
            let _: FederalLoanBulkOut = try await post(
                path: "/federal-loans/bulk",
                body: federalPayload,
                as: FederalLoanBulkOut.self
            )
            print("We got past federal loan")

            // 2. POST /private-loans/bulk
            let privatePayload = PrivateLoanBulkIn(loans: onboardingState.privateLoans)
            let _: PrivateLoanBulkOut = try await post(
                path: "/private-loans/bulk",
                body: privatePayload,
                as: PrivateLoanBulkOut.self
            )
            print("We got past private pay load")

            // 3. POST /job-offer
            if let jobOffer = onboardingState.jobOffer {
                let jobOut: JobOfferOut = try await post(
                    path: "/job-offer",
                    body: jobOffer,
                    as: JobOfferOut.self
                )
                await MainActor.run { planVM.jobOffer = jobOut }
            }
            print("We got past job offer")
            
            // 4. POST /housing
            if let housing = onboardingState.housing {
                let housingOut: HousingOut = try await post(
                    path: "/housing",
                    body: housing,
                    as: HousingOut.self
                )
                await MainActor.run { planVM.housing = housingOut }
            }

            // 5. POST /plan/calculate
            await MainActor.run { planVM.monthlyExpenses = Decimal(onboardingState.monthlyExpenses) }
            await planVM.recalculate()

            await MainActor.run { transition(to: .main) }

        } catch {
            print("⚠️ Onboarding submission error: \(error.localizedDescription)")
            await MainActor.run {
                planVM.monthlyExpenses = Decimal(onboardingState.monthlyExpenses)
                planVM.errorMessage = error.localizedDescription
                transition(to: .main)
            }
        }
    }

    // MARK: - Transition Helper

    private func transition(to next: AppScreen) {
        withAnimation(.easeInOut(duration: 0.35)) {
            screen = next
        }
    }
}
