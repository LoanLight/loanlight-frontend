//
//  ConfirmationView.swift
//  loanlight
//
//  Created by Sruthy Mammen on 2/22/26.
//
//
import SwiftUI

// Shows only the fields the API actually needs:
// loan_name (from loanType), balance, interest_rate, min_monthly_payment

struct LoanConfirmationView: View {
    @State var loan: LoanEntity
    var onSave: (LoanEntity) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Extracted badge ───────────────────────────
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

                        // ── The 3 fields the API needs ────────────────
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

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }

                // ── CTA ───────────────────────────────────────────────
                VStack(spacing: 10) {
                    Button(action: { onSave(loan); dismiss() }) {
                        Text("Save & Continue")
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
                .padding(.bottom, 36)
                .padding(.top, 12)
            }
        }
    }
}

// MARK: - EditableField (only the fields that matter)

struct EditableField: View {
    let label: String
    @Binding var value: String
    var placeholder: String = "Enter value"
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(AppFont.sectionLabel)
                .tracking(1.1)
                .foregroundColor(.mist)

            HStack {
                TextField(placeholder, text: $value)
                    .font(AppFont.bodyMedium ?? .body)
                    .foregroundColor(value.isEmpty ? .mist : .ink)
                    .focused($focused)

                if !focused {
                    Button("Edit") { focused = true }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.sage)
                }
            }
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(focused ? Color.sage.opacity(0.5) : Color.border, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: focused)
    }
}

