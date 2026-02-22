import SwiftUI

enum AppScreen {
    case onboarding
    case main
}

// MARK: - AppCoordinator

struct AppCoordinator: View {
    @State private var currentScreen: AppScreen = .onboarding

    var body: some View {
        switch currentScreen {
        case .onboarding:
            FederalLoansView(currentStep: 1, totalSteps: 6) { confirmedLoans in
                // Onboarding done — transition to main plan screen
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentScreen = .main
                }
            }
        case .main:
            MainTabView()
        }
    }
}
