//
//  PrivateLoansConfirmationView.swift
//  loanlight
//

import SwiftUI

struct PrivateLoansConfirmationView: View {

    @State var loans: [LoanEntity]
    var onSave: ([LoanEntity]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var expandedLoanId: UUID? = nil

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {

                // Progress Bar
                HStack(spacing: 4) {
                    ForEach(1...7, id: \.self) { step in
                        RoundedRectangle(cornerRadius: 2)
                            .frame(height: 3)
                            .foregroundColor(step <= 4 ? .primary : Color(.systemGray5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // Step Pill
                        HStack(spacing: 6) {
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.primary)
                            Text("STEP 4 OF 7")
                                .font(AppFont.chip)
                                .foregroundColor(.primary)
                                .tracked(.wide)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().stroke(Color.primary.opacity(0.3), lineWidth: 1))
                        .padding(.bottom, 14)

                        Text("Review Private Loans")
                            .font(AppFont.serif(28))
                            .foregroundColor(.primaryText)
                            .padding(.bottom, 6)

                        Text("We extracted these fields from your PDFs.\nTap any loan to edit its details.")
                            .font(AppFont.body)
                            .foregroundColor(.secondaryText)
                            .lineSpacing(3)
                            .padding(.bottom, 16)

                        HStack(spacing: 6) {
                            Text("✦")
                                .font(AppFont.micro)
                                .foregroundColor(.primary)
                            Text("\(loans.count) loan\(loans.count == 1 ? "" : "s") extracted")
                                .font(AppFont.captionBold)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.primaryTint)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.bottom, 24)

                        // One expandable card per loan
                        ForEach($loans) { $loan in
                            LoanEditCard(loan: $loan, isExpanded: expandedLoanId == loan.id) {
                                withAnimation(.spring(response: 0.3)) {
                                    expandedLoanId = expandedLoanId == loan.id ? nil : loan.id
                                }
                            }
                            .padding(.bottom, 12)
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 24)
                }

                // Save Button
                Button(action: {
                    onSave(loans)
                }) {
                    Text("Confirm & Continue")
                        .font(AppFont.ctaButton)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .padding(.top, 12)
            }
        }
    }
}

// MARK: - Expandable Loan Edit Card

struct LoanEditCard: View {
    @Binding var loan: LoanEntity
    var isExpanded: Bool
    var onTapHeader: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header row — always visible
            Button(action: onTapHeader) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                        .font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loan.servicer.isEmpty ? "Private Loan" : loan.servicer)
                            .font(AppFont.bodySemibold)
                            .foregroundColor(.primaryText)
                        Text([loan.totalBalance, loan.interestRate]
                            .filter { !$0.isEmpty }
                            .joined(separator: " · "))
                            .font(AppFont.caption)
                            .foregroundColor(.secondaryText)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondaryText)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded edit fields
            if isExpanded {
                VStack(spacing: 0) {
                    Divider().background(Color.cardBorder).padding(.horizontal, 16)
                    VStack(spacing: 0) {
                        EditableField(label: "LENDER",          value: $loan.servicer)
                        EditableField(label: "TOTAL BALANCE",   value: $loan.totalBalance)
                        EditableField(label: "LOAN TYPE",       value: $loan.loanType)
                        EditableField(label: "INTEREST RATE",   value: $loan.interestRate)
                        EditableField(label: "REPAYMENT PLAN",  value: $loan.repaymentPlan)
                        EditableField(label: "MONTHLY PAYMENT", value: $loan.monthlyPayment)
                        EditableField(label: "LOAN STATUS",     value: $loan.loanStatus)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardBorder, lineWidth: 1))
        .animation(.spring(response: 0.3), value: isExpanded)
    }
}

// MARK: - Preview

#Preview {
    var loan1 = LoanEntity()
    loan1.servicer       = "Sallie Mae"
    loan1.totalBalance   = "$24,800.00"
    loan1.loanType       = "Private"
    loan1.interestRate   = "9.25%"
    loan1.repaymentPlan  = "Fixed"
    loan1.monthlyPayment = "$278.00"
    loan1.loanStatus     = "In Repayment"

    var loan2 = LoanEntity()
    loan2.servicer       = "Discover"
    loan2.totalBalance   = "$11,500.00"
    loan2.loanType       = "Private"
    loan2.interestRate   = "7.75%"
    loan2.repaymentPlan  = "Fixed"
    loan2.monthlyPayment = "$142.00"
    loan2.loanStatus     = "In Repayment"

    return PrivateLoansConfirmationView(loans: [loan1, loan2]) { saved in
        print("Saved \(saved.count) loans")
    }
}
