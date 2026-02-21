import SwiftUI

/// The core slider on the plan screen.
///
/// - Investing OFF: slider controls total monthly loan payment (min → max).
///   Moving it right = more debt payment = earlier freedom date.
///
/// - Investing ON: slider controls monthly investment amount (0 → maxInvestment).
///   Loan payment stays at minimum. Moving it right = more investing.
struct PaymentSliderView: View {
    let investingEnabled: Bool

    // Debt-only mode bindings
    @Binding var monthlyCommitment: Decimal
    let sliderMin: Decimal
    let sliderMax: Decimal

    // Investing mode bindings
    @Binding var monthlyInvestment: Decimal
    let maxInvestment: Decimal
    let minimumLoanPayment: Decimal

    var body: some View {
        VStack(spacing: 0) {
            // ── Label row ─────────────────────────────────────
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(investingEnabled ? "Monthly Investment" : "Monthly Loan Payment")
                        .font(AppFont.bodySemibold)
                        .foregroundColor(.ink)
                    Text(investingEnabled
                         ? "Above your \(minimumLoanPayment.formatted(.currency(code: "USD"))) minimum payments"
                         : "Drag to accelerate payoff")
                        .font(AppFont.caption)
                        .foregroundColor(.mist)
                }
                Spacer()
                // Big number display
                Text(currentValueFormatted)
                    .font(AppFont.serif(26))
                    .foregroundColor(investingEnabled ? .gold : .sage)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: monthlyCommitment)
                    .animation(.easeInOut(duration: 0.2), value: monthlyInvestment)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // ── Slider ────────────────────────────────────────
            VStack(spacing: 6) {
                if investingEnabled {
                    StyledSlider(
                        value: Binding(
                            get: { Double(truncating: monthlyInvestment as NSDecimalNumber) },
                            set: { monthlyInvestment = Decimal($0) }
                        ),
                        range: 0...max(1, Double(truncating: maxInvestment as NSDecimalNumber)),
                        color: .gold
                    )
                } else {
                    StyledSlider(
                        value: Binding(
                            get: { Double(truncating: monthlyCommitment as NSDecimalNumber) },
                            set: { monthlyCommitment = Decimal($0) }
                        ),
                        range: Double(truncating: sliderMin as NSDecimalNumber)...max(
                            Double(truncating: sliderMin as NSDecimalNumber) + 1,
                            Double(truncating: sliderMax as NSDecimalNumber)
                        ),
                        color: .sage
                    )
                }

                // Min / Max labels
                HStack {
                    Text(investingEnabled ? "$0" : sliderMin.formatted(.currency(code: "USD")))
                        .font(.system(size: 10))
                        .foregroundColor(.mist)
                    Spacer()
                    Text(investingEnabled
                         ? maxInvestment.formatted(.currency(code: "USD"))
                         : sliderMax.formatted(.currency(code: "USD")))
                        .font(.system(size: 10))
                        .foregroundColor(.mist)
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            // ── Hint banner ───────────────────────────────────
            if !investingEnabled {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.sage)
                    Text("Higher payments → earlier freedom date")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.sage)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.surface)
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.border, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    private var currentValueFormatted: String {
        if investingEnabled {
            return monthlyInvestment.formatted(.currency(code: "USD"))
        } else {
            return monthlyCommitment.formatted(.currency(code: "USD"))
        }
    }
}

// MARK: - Styled Slider

/// A slider that matches the app's sage/invest color scheme.
private struct StyledSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color

    var body: some View {
        Slider(value: $value, in: range)
            .tint(color)
    }
}
