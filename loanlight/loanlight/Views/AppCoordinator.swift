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
    @State private var authCheckComplete = false
    @State private var splashComplete = false

    var body: some View {
        Group {
            if isCheckingAuth {
                // Show branded splash while checking auth
                SplashView(onComplete: {
                    splashComplete = true
                    if authCheckComplete { isCheckingAuth = false }
                })
            } else {
                switch screen {
                case .auth:
                    AuthFlowView(onAuthenticated: {
                        transition(to: .onboarding(.federalLoans))
                    })
                case .onboarding(let step):
                    onboardingView(for: step)
                case .main:
                    MainTabView(planVM: planVM, onLogout: {
                        planVM.reset()
                        transition(to: .auth)
                    })
                }
            }
        }
        .task {
            await checkAuthAndRoute()
        }
    }

    // MARK: - Launch routing

    private func checkAuthAndRoute() async {
        defer {
            authCheckComplete = true
            if splashComplete { isCheckingAuth = false }
        }

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




// MARK: - SplashView
// Shows the FirstLoadingView animation without its internal navigation.
// AppCoordinator replaces it as soon as the auth check completes.

private struct SplashView: View {
    var onComplete: (() -> Void)? = nil

    @State private var isLit: Bool = false
    @State private var bounceOffset: CGFloat = 0
    @State private var glowOpacity: Double = 0
    @State private var fadeOut: Bool = false

    var body: some View {
        ZStack {
            Color(red: 0.980, green: 0.980, blue: 0.973).ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    (isLit
                                        ? Color(red: 0.239, green: 0.420, blue: 0.369)
                                        : Color(red: 0.788, green: 0.659, blue: 0.298)
                                    ).opacity(0.55),
                                    Color.clear
                                ],
                                center: .center, startRadius: 0, endRadius: 120
                            )
                        )
                        .frame(width: 400, height: 400)
                        .opacity(glowOpacity)
                        .blur(radius: 30)
                        .animation(.easeInOut(duration: 0.4), value: isLit)

                    Image(isLit ? "bulb_blue" : "bulb_yellow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280, height: 280)
                        .offset(y: bounceOffset)
                        .shadow(
                            color: isLit
                                ? Color(red: 0.239, green: 0.420, blue: 0.369).opacity(0.8)
                                : Color(red: 0.788, green: 0.659, blue: 0.298).opacity(0.6),
                            radius: isLit ? 36 : 12
                        )
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .opacity(fadeOut ? 0 : 1)
            .animation(.easeInOut(duration: 0.5), value: fadeOut)
        }
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        // 1. Gentle bounce
        withAnimation(.interpolatingSpring(stiffness: 200, damping: 8).repeatCount(2, autoreverses: true)) {
            bounceOffset = -14
        }

        // 2. Big jump → light up at peak
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
                bounceOffset = -36
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeIn(duration: 0.15))  { isLit = true }
                withAnimation(.easeOut(duration: 0.7))  { glowOpacity = 1.0 }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.08)) {
                    bounceOffset = 0
                }
            }
        }

        // 3. Hold lit for a beat, fade out, then signal complete
        // Total: 1.2 + 0.18 + 1.8 hold = ~3.2s before fade starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.easeInOut(duration: 0.5)) { fadeOut = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete?()
            }
        }
    }
}
