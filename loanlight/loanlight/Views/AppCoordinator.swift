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
    var pendingPrivateLoans: [LoanEntity]    = []   // held for confirmation screen
    var privateLoans: [PrivateLoanIn]        = []   // finalized after confirmation
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
            // User uploads all private loans, taps Continue —
            // passes [LoanEntity] so confirmation screen can show/edit them
            PrivateLoanView(
                currentStep: 3,
                totalSteps: 7,
                onContinue: { loanEntities in
                    if loanEntities.isEmpty {
                        // Skipped — go straight to offer letter
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
                    // Convert confirmed LoanEntities to PrivateLoanIn for backend
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

