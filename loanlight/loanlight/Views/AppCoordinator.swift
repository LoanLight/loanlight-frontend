import SwiftUI

// MARK: - Screen Enum

enum AppScreen {
    case auth
    case onboarding(OnboardingStep)
    case main
}

enum OnboardingStep {
    case federalLoans
    case confirmFederalLoans
    case privateLoans
    case confirmPrivateLoans
    case offerLetter
    case location
    case loading
}

// MARK: - Onboarding State

private final class OnboardingState {
    var confirmedFederalLoans: [LoanEntity] = []
    var pendingPrivateLoans: [LoanEntity]   = []
    var privateLoans: [PrivateLoanIn]       = []
    var jobOffer: JobOfferIn?               = nil
    var housing: HousingIn?                 = nil
    var monthlyExpenses: Double             = 0
}

// MARK: - AppCoordinator

struct AppCoordinator: View {
    @State private var screen: AppScreen = .auth
    @State private var onboardingState = OnboardingState()
    @StateObject private var planVM = PlanViewModel()
    @State private var isCheckingAuth = true

    var body: some View {
        Group {
            if isCheckingAuth {
                // Brief auth check — show nothing or a splash
                Color.paper.ignoresSafeArea()
            } else {
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
        .task {
            await checkAuthAndRoute()
        }
    }

    // MARK: - Launch routing

    private func checkAuthAndRoute() async {
        defer { isCheckingAuth = false }

        guard TokenStore.isLoggedIn else {
            screen = .auth
            return
        }

        // Check if profile is complete
        do {
            let status: ProfileCompleteResponse = try await APIClient.get(path: "/profile/complete")
            if status.complete {
                await loadExistingProfile()
                screen = .main
            } else {
                screen = .onboarding(.federalLoans)
            }
        } catch {
            // Token may be expired — send back to auth
            TokenStore.clearToken()
            screen = .auth
        }
    }

    private func loadExistingProfile() async {
        do {
            async let jobOfferTask: JobOfferOut  = APIClient.get(path: "/job-offer/current")
            async let housingTask: HousingOut    = APIClient.get(path: "/housing/current")

            let (jobOffer, housing) = try await (jobOfferTask, housingTask)
            planVM.jobOffer = jobOffer
            planVM.housing  = housing

            // Pre-fetch limits then calculate initial plan
            await planVM.fetchLimits()
            await planVM.recalculate()
        } catch {
            print("[AppCoordinator] loadExistingProfile error: \(error)")
        }
    }

    // MARK: - Onboarding Step Views

    @ViewBuilder
    private func onboardingView(for step: OnboardingStep) -> some View {
        switch step {

        case .federalLoans:
            FederalLoansView(currentStep: 1, totalSteps: 7, onComplete: { loans in
                onboardingState.confirmedFederalLoans = loans
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
                // Fire-and-forget all submissions, then go to main
                Task {
                    await submitOnboardingData()
                    await MainActor.run {
                        transition(to: .main)
                    }
                }
            }
        }
    }

    // MARK: - Submit all onboarding data

    private func submitOnboardingData() async {
        planVM.monthlyExpenses = Decimal(onboardingState.monthlyExpenses)

        // 1. Federal loans (already submitted in FederalLoansView, but we re-submit
        //    here to ensure it's stored; idempotent since it's "replace all")
        let federalLoans = onboardingState.confirmedFederalLoans.map { $0.toFederalLoanIn() }
        if !federalLoans.isEmpty {
            do {
                let _: FederalLoanBulkOut = try await APIClient.post(
                    path: "/federal-loans/bulk",
                    body: FederalLoanBulkIn(loans: federalLoans)
                )
            } catch {
                print("[AppCoordinator] federal loans error: \(error)")
            }
        }

        // 2. Private loans
        if !onboardingState.privateLoans.isEmpty {
            do {
                let _: PrivateLoanBulkOut = try await APIClient.post(
                    path: "/private-loans/bulk",
                    body: PrivateLoanBulkIn(loans: onboardingState.privateLoans)
                )
            } catch {
                print("[AppCoordinator] private loans error: \(error)")
            }
        }

        // 3. Job offer
        if let jobOfferIn = onboardingState.jobOffer {
            do {
                let jobOfferOut: JobOfferOut = try await APIClient.post(
                    path: "/job-offer",
                    body: jobOfferIn
                )
                planVM.jobOffer = jobOfferOut
            } catch {
                print("[AppCoordinator] job offer error: \(error)")
            }
        }

        // 4. Housing
        if let housingIn = onboardingState.housing {
            do {
                let housingOut: HousingOut = try await APIClient.post(
                    path: "/housing",
                    body: housingIn
                )
                planVM.housing = housingOut
            } catch {
                print("[AppCoordinator] housing error: \(error)")
            }
        }

        // 5. Fetch limits, then calculate initial plan
        await planVM.fetchLimits()
        await planVM.recalculate()
    }

    // MARK: - Transition

    private func transition(to next: AppScreen) {
        withAnimation(.easeInOut(duration: 0.35)) {
            screen = next
        }
    }
}
