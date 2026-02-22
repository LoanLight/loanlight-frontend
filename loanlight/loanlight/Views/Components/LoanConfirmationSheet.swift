import SwiftUI

/// Bottom sheet shown after PDF extraction.
/// Lets the user review and edit the extracted fields before confirming.
struct LoanConfirmationSheet: View {
    @State var loan: LoanEntity
    var onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.paper.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.success)
                                .font(.system(size: 14))
                            Text("Data extracted successfully")
                                .font(AppFont.captionBold)
                                .foregroundColor(.success)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.success.opacity(0.08))
                        .cornerRadius(10)
                        .padding(.bottom, 20)

                        Text("Review Loan Details")
                            .font(AppFont.serif(22))
                            .foregroundColor(.ink)
                            .padding(.bottom, 6)

                        Text("Tap any field to correct it.")
                            .font(AppFont.caption)
                            .foregroundColor(.mist)
                            .padding(.bottom, 24)

                        // ── Editable fields ──────────────────────
                        VStack(spacing: 1) {
                            editRow(label: "Servicer",        value: $loan.servicer)
                            editRow(label: "Loan Type",       value: $loan.loanType)
                            editRow(label: "Total Balance",   value: $loan.totalBalance)
                            editRow(label: "Interest Rate",   value: $loan.interestRate)
                            editRow(label: "Monthly Payment", value: $loan.monthlyPayment)
                            editRow(label: "Repayment Plan",  value: $loan.repaymentPlan)
                            editRow(label: "Status",          value: $loan.loanStatus,     isLast: true)
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.border, lineWidth: 1))
                        .padding(.bottom, 28)

                        // ── Confirm button ───────────────────────
                        Button(action: {
                            onConfirm()
                            dismiss()
                        }) {
                            Text("Confirm & Add Loan")
                                .font(AppFont.ctaButton)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 17)
                                .background(Color.sage)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button(action: { dismiss() }) {
                            Text("Re-upload PDF")
                                .font(AppFont.ctaButton)
                                .foregroundColor(.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 17)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.border, lineWidth: 1.5)
                                )
                        }
                        .padding(.top, 10)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Review Loan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.sage)
                }
            }
        }
    }

    // MARK: - Editable Row

    private func editRow(
        label: String,
        value: Binding<String>,
        prefix: String = "",
        suffix: String = "",
        isLast: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Text(label)
                    .font(AppFont.caption)
                    .foregroundColor(.mist)
                    .frame(width: 130, alignment: .leading)

                HStack(spacing: 2) {
                    if !prefix.isEmpty {
                        Text(prefix)
                            .font(AppFont.bodyMedium)
                            .foregroundColor(.ink)
                    }
                    TextField("—", text: value)
                        .font(AppFont.bodyMedium)
                        .foregroundColor(.ink)
                        .multilineTextAlignment(.trailing)
                    if !suffix.isEmpty {
                        Text(suffix)
                            .font(AppFont.bodyMedium)
                            .foregroundColor(.ink)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if !isLast {
                Divider()
                    .background(Color.border)
                    .padding(.leading, 16)
            }
        }
    }
}
