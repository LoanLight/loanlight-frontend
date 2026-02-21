import SwiftUI
import Charts

/// Live chart that plots the month-by-month series from PlanCalculateResponse.
/// Shows loan balance declining and (optionally) investment balance growing.
/// Marks the freedom date with a vertical rule.
struct PlanProjectionChartView: View {
    let series: [SeriesPoint]
    let investingEnabled: Bool
    let freedomDate: String
    let monthsToFreedom: Int

    @State private var chartTab: ChartTab = .balances

    enum ChartTab: String, CaseIterable, Identifiable {
        case balances = "Balances"
        case netWorth = "Net Worth"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            chartSection
        }
        .background(Color.white)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.border, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Projection")
                        .font(AppFont.serif(17))
                        .foregroundColor(.ink)
                    Text("\(monthsToFreedom) months to freedom")
                        .font(AppFont.caption)
                        .foregroundColor(.mist)
                }
                Spacer()
                HStack(spacing: 5) {
                    Text("🏁").font(.system(size: 11))
                    Text(freedomDate)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.sage)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.sagetint)
                .cornerRadius(20)
            }

            // Tab chips
            HStack(spacing: 6) {
                ForEach(ChartTab.allCases) { tab in
                    Button(action: { withAnimation { chartTab = tab } }) {
                        Text(tab.rawValue)
                            .font(AppFont.chip)
                            .foregroundColor(chartTab == tab ? .white : .mist)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(chartTab == tab ? Color.ink : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.border, lineWidth: chartTab == tab ? 0 : 1.5)
                            )
                            .clipShape(Capsule())
                    }
                }
            }

            // Legend
            HStack(spacing: 14) {
                legendDot(color: .sage, dashed: false, label: "Loan Balance")
                if investingEnabled && chartTab == .balances {
                    legendDot(color: .gold, dashed: true, label: "Investments")
                }
            }
        }
        .padding(16)
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        Group {
            if series.isEmpty {
                ZStack {
                    Rectangle().fill(Color.surface).frame(height: 180)
                    VStack(spacing: 8) {
                        ProgressView().tint(.sage)
                        Text("Calculating…")
                            .font(AppFont.caption)
                            .foregroundColor(.mist)
                    }
                }
                .cornerRadius(12)
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            } else {
                Chart {
                    loanContent
                    investmentContent
                    freedomRuleMark
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 12)) { val in
                        AxisValueLabel {
                            if let m = val.as(Int.self) {
                                Text(monthLabel(m))
                                    .font(.system(size: 9))
                                    .foregroundColor(.mist)
                            }
                        }
                        AxisGridLine().foregroundStyle(Color(hex: "#f0eeea"))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { val in
                        AxisGridLine().foregroundStyle(Color(hex: "#f0eeea"))
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                Text(shortLabel(v))
                                    .font(.system(size: 9))
                                    .foregroundColor(.mist)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
                .animation(.easeInOut(duration: 0.35), value: chartTab)
                .animation(.easeInOut(duration: 0.35), value: investingEnabled)
            }
        }
    }

    // MARK: - Chart Content Builders

    /// Loan balance line — or net worth line depending on active tab
    @ChartContentBuilder
    private var loanContent: some ChartContent {
        ForEach(series, id: \.id) { point in
            AreaMark(
                x: .value("Month", point.monthIndex),
                y: .value("Loan", loanY(for: point))
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.sage.opacity(0.18), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            LineMark(
                x: .value("Month", point.monthIndex),
                y: .value("Loan", loanY(for: point))
            )
            .foregroundStyle(Color.sage)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
    }

    /// Investment balance line — only shown when investing is on and balances tab active
    @ChartContentBuilder
    private var investmentContent: some ChartContent {
        if investingEnabled && chartTab == .balances {
            ForEach(series, id: \.id) { point in
                AreaMark(
                    x: .value("Month", point.monthIndex),
                    y: .value("Investment", investY(for: point))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.gold.opacity(0.12), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                LineMark(
                    x: .value("Month", point.monthIndex),
                    y: .value("Investment", investY(for: point))
                )
                .foregroundStyle(Color.gold)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [5, 4]))
            }
        }
    }

    /// Vertical rule at the freedom date
    @ChartContentBuilder
    private var freedomRuleMark: some ChartContent {
        if let freedomPoint = series.last(where: { $0.remainingLoanBalance <= 0 }) {
            RuleMark(x: .value("Freedom", freedomPoint.monthIndex))
                .foregroundStyle(Color.sage.opacity(0.35))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .annotation(position: .top, alignment: .leading) {
                    Text("🏁").font(.system(size: 10))
                }
        }
    }

    // MARK: - Y value helpers
    // Pulling the Decimal→Double conversion out of the Chart builder entirely

    private func loanY(for point: SeriesPoint) -> Double {
        if chartTab == .balances {
            return NSDecimalNumber(decimal: point.remainingLoanBalance).doubleValue
        } else {
            // Net worth = investments - remaining debt
            let inv  = NSDecimalNumber(decimal: point.investmentBalance).doubleValue
            let loan = NSDecimalNumber(decimal: point.remainingLoanBalance).doubleValue
            return inv - loan
        }
    }

    private func investY(for point: SeriesPoint) -> Double {
        NSDecimalNumber(decimal: point.investmentBalance).doubleValue
    }

    // MARK: - Axis label helpers

    private func monthLabel(_ index: Int) -> String {
        let year = Calendar.current.component(.year, from: Date()) + index / 12
        return "'\(String(year).suffix(2))"
    }

    private func shortLabel(_ v: Double) -> String {
        if abs(v) >= 1000 { return "$\(Int(v / 1000))k" }
        return v >= 0 ? "$0" : "-$0"
    }

    // MARK: - Legend

    private func legendDot(color: Color, dashed: Bool, label: String) -> some View {
        HStack(spacing: 5) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle().fill(color.opacity(0.8)).frame(width: 4, height: 2)
                    }
                }
            } else {
                Rectangle().fill(color).frame(width: 16, height: 2).cornerRadius(1)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.mist)
        }
    }
}
