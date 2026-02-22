import SwiftUI

/// The 4-card results grid shown below the chart.
/// Cards differ based on whether investing is on or off.
struct PlanResultsView: View {
    let response: PlanCalculateResponse
    let investingEnabled: Bool

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 10
        ) {
            // ── Freedom Date — always shown, sage gradient ─────
            MetricCard(
                label: "Freedom Date",
                value: freedomDateFormatted,
                delta: "\(response.monthsToFreedom) months away",
                style: .sage
            )

            // ── Total Wealth — always shown, gold gradient ─────
            MetricCard(
                label: "Wealth at Freedom",
                value: response.investing.projectedInvestmentValueAtFreedom
                    .formatted(.currency(code: "USD").precision(.fractionLength(0))),
                delta: "investments + debt-free",
                style: .gold
            )

            // ── Monthly payment or investment ──────────────────
            if investingEnabled {
                MetricCard(
                    label: "Monthly Investment",
                    value: response.investing.monthlyInvestment
                        .formatted(.currency(code: "USD")),
                    delta: response.investing.riskLevel.expectedReturnLabel,
                    style: .plain,
                    accentColor: .gold
                )
            } else {
                MetricCard(
                    label: "Monthly Payment",
                    value: response.cashflow.monthlyCommitment
                        .formatted(.currency(code: "USD")),
                    delta: extraAboveMin,
                    style: .plain,
                    accentColor: .sage
                )
            }

            // ── Total interest paid ────────────────────────────
            MetricCard(
                label: "Total Interest",
                value: response.totalInterestPaid
                    .formatted(.currency(code: "USD").precision(.fractionLength(0))),
                delta: "paid over loan life",
                style: .plain,
                accentColor: .mist
            )
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.3), value: investingEnabled)
    }

    private var freedomDateFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: response.freedomDate)
    }

    private var extraAboveMin: String {
        let extra = response.cashflow.extraAboveMinimum
        if extra > 0 {
            return "+ \(extra.formatted(.currency(code: "USD"))) above minimum"
        }
        return "minimum payment"
    }
}

// MARK: - Card Style

private enum CardStyle { case sage, gold, plain }

// MARK: - Single Metric Card

private struct MetricCard: View {
    let label: String
    let value: String
    let delta: String
    let style: CardStyle
    var accentColor: Color = .mist

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.7)
                .textCase(.uppercase)
                .foregroundColor(labelColor)

            Text(value)
                .font(AppFont.serif(20))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(delta)
                .font(AppFont.caption)
                .foregroundColor(deltaColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
        .overlay(
            Group {
                if style == .plain {
                    RoundedRectangle(cornerRadius: 16).stroke(Color.border, lineWidth: 1)
                }
            }
        )
    }

    private var cardBackground: some View {
        Group {
            switch style {
            case .sage:
                LinearGradient(
                    colors: [Color.sage, Color(hex: "#2d5248")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .gold:
                LinearGradient(
                    colors: [Color(hex: "#b8893a"), Color(hex: "#8a6520")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .plain:
                Color.white
            }
        }
    }

    private var labelColor: Color {
        style == .plain ? .mist : .white.opacity(0.65)
    }

    private var valueColor: Color {
        style == .plain ? .ink : .white
    }

    private var deltaColor: Color {
        style == .plain ? accentColor : .white.opacity(0.55)
    }
}
