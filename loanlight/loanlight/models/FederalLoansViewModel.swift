import SwiftUI
import Combine

// MARK: - LoanEntity
// Local onboarding model. Once confirmed, maps to FederalLoanIn for the backend.

struct LoanEntity: Identifiable, Codable {
    var id = UUID()
    var servicer: String = ""
    var totalBalance: String = ""
    var loanType: String = ""
    var interestRate: String = ""
    var repaymentPlan: String = ""
    var monthlyPayment: String = ""
    var loanStatus: String = ""

    /// Convert to the backend request model
    func toFederalLoanIn() -> FederalLoanIn {
        FederalLoanIn(
            loanName: loanType.isEmpty ? "Federal Loan" : loanType,
            balance: Decimal(string: totalBalance
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")) ?? 0,
            interestRate: Decimal(string: interestRate
                .replacingOccurrences(of: "%", with: "")) ?? 0,
            minMonthlyPayment: Decimal(string: monthlyPayment
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: ""))
        )
    }
}

// MARK: - FederalLoansViewModel

@MainActor
class FederalLoansViewModel: ObservableObject {

    @Published var extractedLoan: LoanEntity? = nil
    @Published var confirmedLoans: [LoanEntity] = []
    @Published var showConfirmation = false
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func extractFromURL(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Unable to access file. Please try again."
            return
        }
        isLoading = true
        Task {
            await withCheckedContinuation { continuation in
                LoanPDFExtractor.extract(from: url) { [weak self] result in
                    url.stopAccessingSecurityScopedResource()
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.isLoading = false
                        switch result {
                        case .success(let data):
                            var entity = LoanEntity()
                            entity.servicer       = data.servicer
                            entity.totalBalance   = data.totalBalance
                            entity.loanType       = data.loanType
                            entity.interestRate   = data.interestRate
                            entity.repaymentPlan  = data.repaymentPlan
                            entity.monthlyPayment = data.monthlyPayment
                            entity.loanStatus     = data.loanStatus
                            self.extractedLoan    = entity
                            self.showConfirmation = true
                        case .failure(let error):
                            self.errorMessage = error.localizedDescription
                        }
                        continuation.resume()
                    }
                }
            }
        }
    }

    /// Called by LoanConfirmationView — saves the user-edited loan (not the raw extracted one)
    func confirmLoan(_ loan: LoanEntity) {
        confirmedLoans.append(loan)
        extractedLoan = nil
        showConfirmation = false
    }

    /// Legacy — kept for compatibility but confirmLoan(_:) is preferred
    func confirmExtractedLoan() {
        guard let loan = extractedLoan else { return }
        confirmedLoans.append(loan)
        extractedLoan = nil
        showConfirmation = false
    }
}

