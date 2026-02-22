//
//  ConfirmationView.swift
//  loanlight
//
//  Created by Sruthy Mammen on 2/22/26.
//
//
import SwiftUI

struct LoanConfirmationView: View {

    @State var loan: LoanEntity
    var onSave: (LoanEntity) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Progress Bar ──
                HStack(spacing: 4) {
                    ForEach(1...6, id: \.self) { step in
                        RoundedRectangle(cornerRadius: 2)
                            .frame(height: 3)
                            .foregroundColor(step <= 2 ? .primary : Color(.systemGray5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Step Pill ──
                        HStack(spacing: 6) {
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.primary)
                            Text("CONFIRM DETAILS")
                                .font(AppFont.chip)
                                .foregroundColor(.primary)
                                .tracked(.wide)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().stroke(Color.primary.opacity(0.3), lineWidth: 1))
                        .padding(.bottom, 14)

                        Text("Federal Loan Info")
                            .font(AppFont.serif(28))
                            .foregroundColor(.primaryText)
                            .padding(.bottom, 6)

                        Text("We extracted these fields from your PDF.\nTap any to edit.")
                            .font(AppFont.body)
                            .foregroundColor(.secondaryText)
                            .lineSpacing(3)
                            .padding(.bottom, 16)

                        HStack(spacing: 6) {
                            Text("✦")
                                .font(AppFont.micro)
                                .foregroundColor(.primary)
                            Text("8 fields extracted from PDF")
                                .font(AppFont.captionBold)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.primaryTint)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.bottom, 20)

                        EditableField(label: "SERVICER",        value: $loan.servicer)
                        EditableField(label: "TOTAL BALANCE",   value: $loan.totalBalance)
                        EditableField(label: "LOAN TYPE",       value: $loan.loanType)
                        EditableField(label: "INTEREST RATE",   value: $loan.interestRate)
                        EditableField(label: "REPAYMENT PLAN",  value: $loan.repaymentPlan)
                        EditableField(label: "MONTHLY PAYMENT", value: $loan.monthlyPayment)
                        EditableField(label: "LOAN STATUS",     value: $loan.loanStatus)

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 24)
                }

                Button(action: {
                    onSave(loan)
                    dismiss()
                }) {
                    Text("Save & Continue")
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


struct EditableField: View {
    let label: String
    @Binding var value: String
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(AppFont.sectionLabel)
                .foregroundColor(.secondaryText)
                .tracked(.wide)

            HStack {
                TextField(value.isEmpty ? "Not found — enter manually" : label, text: $value)
                    .font(AppFont.bodySemibold)
                    .foregroundColor(value.isEmpty ? .secondaryText : .primaryText)
                    .focused($focused)

                if !focused {
                    Button("Edit") { focused = true }
                        .font(AppFont.smallButton)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    focused ? Color.primary.opacity(0.6) : Color.cardBorder,
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.15), value: focused)
        .padding(.bottom, 10)
    }
}

#Preview {
    LoanConfirmationView(
        loan: LoanEntity(
            servicer: "MOHELA",
            totalBalance: "$52,400.00",
            loanType: "Direct Sub + Unsub",
            interestRate: "5.50%",
            repaymentPlan: "Standard (10-yr)",
            monthlyPayment: "$569.00",
            loanStatus: "In Repayment"
        )
    ) { saved in
        print("Saved: \(saved)")
    }
}
