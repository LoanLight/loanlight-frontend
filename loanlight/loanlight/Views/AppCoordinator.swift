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
    case confirmFederalLoans   // Step 2 — review extracted loan
    case privateLoans          // Step 3
    case offerLetter           // Step 4
    case location              // Step 5
    case loading               // Step 6
}

// MARK: - Onboarding State

private final class OnboardingState {
    var confirmedFederalLoans: [LoanEntity]  = []
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
                // FIX 1: AuthFlowView uses `onAuthenticated`, not a trailing closure label
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
            FederalLoansView(currentStep: 1, totalSteps: 6, onComplete: { extractedLoans in
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
            // PrivateLoansView uses `onContinue` — correct
            PrivateLoansView(currentStep: 3, totalSteps: 6, onContinue: { privateLoanIns in
                onboardingState.privateLoans = privateLoanIns
                transition(to: .onboarding(.offerLetter))
            })

        case .offerLetter:
            // FIX 3: OfferLetterView uses `onContinue`, not a trailing closure
            OfferLetterView(currentStep: 4, totalSteps: 6, onContinue: { jobOfferIn in
                onboardingState.jobOffer = jobOfferIn
                transition(to: .onboarding(.location))
            })

        case .location:
            // LocationView uses `onContinue` — correct
            LocationView(currentStep: 5, totalSteps: 6, onContinue: { housingIn, expenses in
                onboardingState.housing = housingIn
                onboardingState.monthlyExpenses = expenses
                transition(to: .onboarding(.loading))
            })

        case .loading:
            PlanLoadingView {
                planVM.monthlyExpenses = Decimal(onboardingState.monthlyExpenses)
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
