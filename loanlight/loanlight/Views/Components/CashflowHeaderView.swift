import SwiftUI

/// Shows the three income/expense numbers at the top of the plan screen.
/// Tapping the expenses row lets the user edit it inline.
struct CashflowHeaderView: View {
    let takeHome: Decimal
    let rent: Decimal
    @Binding var expenses: Decimal
    let available: Decimal

    @State private var editingExpenses = false
    @State private var expensesText = ""

    var body: some View {
        VStack(spacing: 0) {
            // ── Take Home ──────────────────────────────────────
            rowView(
                icon: "💰",
                label: "Take-Home Pay",
                value: takeHome,
                valueColor: .sage,
                isEditable: false
            )

            internalDivider

            // ── Rent ───────────────────────────────────────────
            rowView(
                icon: "🏠",
                label: "Est. Monthly Rent",
                value: rent,
                valueColor: .ink,
                isEditable: false,
                sublabel: "HUD estimate"
            )

            internalDivider

            // ── Expenses ───────────────────────────────────────
            HStack(spacing: 12) {
                Text("📦").font(.system(size: 16))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Expenses")
                        .font(AppFont.bodySemibold)
                        .foregroundColor(.ink)
                    Text("Food, transport, subscriptions…")
                        .font(.system(size: 11))
                        .foregroundColor(.mist)
                }
                Spacer()
                if editingExpenses {
                    HStack(spacing: 4) {
                        Text("$").font(AppFont.bodySemibold).foregroundColor(.ink)
                        TextField("0", text: $expensesText)
                            .keyboardType(.decimalPad)
                            .font(AppFont.bodySemibold)
                            .foregroundColor(.ink)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                        Button("Done") {
                            commitExpenses()
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.sage)
                    }
                } else {
                    Button(action: {
                        expensesText = "\(expenses)"
                        editingExpenses = true
                    }) {
                        HStack(spacing: 4) {
                            Text(expenses.formatted(.currency(code: "USD")))
                                .font(AppFont.bodySemibold)
                                .foregroundColor(.ink)
                            Image(systemName: "pencil")
                                .font(.system(size: 10))
                                .foregroundColor(.mist)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            // ── Available total ────────────────────────────────
            HStack {
                Text("Available for loans + investing")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.sage)
                Spacer()
                Text(available.formatted(.currency(code: "USD")))
                    .font(AppFont.serif(16))
                    .foregroundColor(.sage)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.sagemist)
        }
        .background(Color.white)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.border, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    // MARK: - Row

    private func rowView(
        icon: String,
        label: String,
        value: Decimal,
        valueColor: Color,
        isEditable: Bool,
        sublabel: String? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Text(icon).font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppFont.bodySemibold)
                    .foregroundColor(.ink)
                if let sub = sublabel {
                    Text(sub)
                        .font(.system(size: 11))
                        .foregroundColor(.mist)
                }
            }
            Spacer()
            Text(value.formatted(.currency(code: "USD")))
                .font(AppFont.bodySemibold)
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var internalDivider: some View {
        Divider().background(Color.border).padding(.leading, 44)
    }

    // MARK: - Commit

    private func commitExpenses() {
        if let val = Decimal(string: expensesText) {
            expenses = max(0, val)
        }
        editingExpenses = false
    }
}
