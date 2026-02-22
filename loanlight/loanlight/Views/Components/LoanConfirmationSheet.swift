import SwiftUI

/// Sheet shown after PDF extraction — only the 3 fields the API needs
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

                        // ── Badge ──────────────────────────────────────
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.sage)
                                .font(.system(size: 13))
                            Text("Fields extracted from PDF")
                                .font(AppFont.captionBold)
                                .foregroundColor(.sage)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.sage.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.bottom, 20)

                        Text("Confirm Loan Details")
                            .font(AppFont.serif(24))
                            .foregroundColor(.ink)
                            .padding(.bottom, 6)

                        Text("Only what's needed for your plan. Tap any field to edit.")
                            .font(AppFont.caption)
                            .foregroundColor(.mist)
                            .padding(.bottom, 24)

                        // ── The 3 fields the API needs ─────────────────
                        VStack(spacing: 10) {
                            EditableField(label: "LOAN TYPE / NAME", value: $loan.loanType,
                                          placeholder: "e.g. Direct Subsidized")
                            EditableField(label: "TOTAL BALANCE",    value: $loan.totalBalance,
                                          placeholder: "e.g. 18750.00")
                            EditableField(label: "INTEREST RATE",    value: $loan.interestRate,
                                          placeholder: "e.g. 4.990")
                            EditableField(label: "MIN MONTHLY PAYMENT", value: $loan.monthlyPayment,
                                          placeholder: "e.g. 195.00 (0 if deferred)")
                        }
                        .padding(.bottom, 28)
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
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button(action: { onConfirm(); dismiss() }) {
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
                            .font(AppFont.body.weight(.medium))
                            .foregroundColor(.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.border, lineWidth: 1.5)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .padding(.top, 8)
                .background(Color.paper)
            }
        }
    }
}
