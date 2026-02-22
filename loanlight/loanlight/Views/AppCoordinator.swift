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
    case federalLoans   // Step 1
    case privateLoans   // Step 2
    case offerLetter    // Step 3
    case location       // Step 4
    case loading        // Step 5
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
            // FIX 2: FederalLoansView uses `onComplete`, not a trailing closure
            FederalLoansView(currentStep: 1, totalSteps: 5, onComplete: { confirmedLoans in
                onboardingState.confirmedFederalLoans = confirmedLoans
                transition(to: .onboarding(.privateLoans))
            })

        case .privateLoans:
            // PrivateLoansView uses `onContinue` — correct
            PrivateLoansView(currentStep: 2, totalSteps: 5, onContinue: { privateLoanIns in
                onboardingState.privateLoans = privateLoanIns
                transition(to: .onboarding(.offerLetter))
            })

        case .offerLetter:
            // FIX 3: OfferLetterView uses `onContinue`, not a trailing closure
            OfferLetterView(currentStep: 3, totalSteps: 5, onContinue: { jobOfferIn in
                onboardingState.jobOffer = jobOfferIn
                transition(to: .onboarding(.location))
            })

        case .location:
            // LocationView uses `onContinue` — correct
            LocationView(currentStep: 4, totalSteps: 5, onContinue: { housingIn, expenses in
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
