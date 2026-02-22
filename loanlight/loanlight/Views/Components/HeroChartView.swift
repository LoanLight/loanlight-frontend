import SwiftUI
import Charts

// MARK: - HeroChartView
//
// Full-bleed chart hero. Sits at the very top of PlanView,
// extends under the status bar, spans edge to edge.
// Dark ink background with sage (loan) and gold (investment) lines.

struct HeroChartView: View {
    let series: [SeriesPoint]
    let investingEnabled: Bool
    let freedomDate: String
    let monthsToFreedom: Int

    // Touch interaction state
    @State private var selectedIndex: Int? = nil
    @State private var tooltipOffset: CGFloat = 0

    // Height of the chart hero block — tall enough to feel cinematic
    private let heroHeight: CGFloat = 320

    var body: some View {
        ZStack(alignment: .top) {
            // ── Ink background — bleeds under status bar ──────
            Color.paper
                .frame(height: heroHeight)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                // ── Header row ────────────────────────────────
                headerRow
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                // ── Chart ─────────────────────────────────────
                chartBody
                    .padding(.top, 4)

                // ── X-axis labels ─────────────────────────────
                xAxisLabels
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
        .frame(height: heroHeight)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Plan")
                    .font(AppFont.serif(26))
                    .foregroundColor(.ink)

                // Animated freedom date
                HStack(spacing: 6) {
                    Text("Free \(freedomDate)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.gold)
                }
            }

            Spacer()

            // Legend + months badge
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 12) {
                    legendItem(color: .sage, dashed: false, label: "Debt")
                    if investingEnabled {
                        legendItem(color: .gold, dashed: true, label: "Wealth")
                    }
                }

                Text("\(monthsToFreedom) mo")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.gold)
                    .cornerRadius(20)
            }
        }
    }

    // MARK: - Chart Body

    private var chartBody: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // ── Main chart ─────────────────────────────────
                Chart {
                    loanContent
                    investmentContent
                    freedomRule
                    if let idx = selectedIndex, idx < series.count {
                        selectedRule(at: idx)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { val in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                Text(shortLabel(v))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.mist)
                            }
                        }
                    }
                }
                .chartPlotStyle { plot in
                    plot.frame(height: 160)
                }
                .frame(width: geo.size.width, height: 180)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            updateSelection(x: val.location.x, width: geo.size.width)
                        }
                        .onEnded { _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                selectedIndex = nil
                            }
                        }
                )

                // ── Floating tooltip ───────────────────────────
                if let idx = selectedIndex, idx < series.count {
                    tooltipView(for: series[idx], in: geo)
                        .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .bottom)))
                }
            }
        }
        .frame(height: 180)
    }

    // MARK: - Chart Content Builders

    @ChartContentBuilder
    private var loanContent: some ChartContent {
        ForEach(series, id: \.id) { point in
            AreaMark(
                x: .value("Month", point.monthIndex),
                y: .value("Loan", NSDecimalNumber(decimal: point.remainingLoanBalance).doubleValue)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.sage.opacity(0.35), Color.sage.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            LineMark(
                x: .value("Month", point.monthIndex),
                y: .value("Loan", NSDecimalNumber(decimal: point.remainingLoanBalance).doubleValue)
            )
            .foregroundStyle(Color.sage)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .symbol {
                if point.monthIndex % 12 == 0 {
                    Circle()
                        .fill(Color.sage)
                        .frame(width: 7, height: 7)
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                }
            }
        }
    }

    @ChartContentBuilder
    private var investmentContent: some ChartContent {
        if investingEnabled {
            ForEach(series, id: \.id) { point in
                AreaMark(
                    x: .value("Month", point.monthIndex),
                    y: .value("Invest", NSDecimalNumber(decimal: point.investmentBalance).doubleValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.gold.opacity(0.18), Color.gold.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                LineMark(
                    x: .value("Month", point.monthIndex),
                    y: .value("Invest", NSDecimalNumber(decimal: point.investmentBalance).doubleValue)
                )
                .foregroundStyle(Color.gold)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 4]))
                .symbol {
                    if point.monthIndex % 12 == 0 {
                        Circle()
                            .fill(Color.gold)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
    }

    @ChartContentBuilder
    private var freedomRule: some ChartContent {
        if let pt = series.last(where: { $0.remainingLoanBalance <= 0 }) {
            RuleMark(x: .value("Freedom", pt.monthIndex))
                .foregroundStyle(Color.white.opacity(0.15))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
    }

    @ChartContentBuilder
    private func selectedRule(at index: Int) -> some ChartContent {
        RuleMark(x: .value("Selected", series[index].monthIndex))
            .foregroundStyle(Color.white.opacity(0.25))
            .lineStyle(StrokeStyle(lineWidth: 1))
    }

    // MARK: - Tooltip

    private func tooltipView(for point: SeriesPoint, in geo: GeometryProxy) -> some View {
        let loan   = NSDecimalNumber(decimal: point.remainingLoanBalance).doubleValue
        let invest = NSDecimalNumber(decimal: point.investmentBalance).doubleValue
        let xFrac  = series.count > 1
            ? CGFloat(point.monthIndex) / CGFloat(series.last?.monthIndex ?? 1)
            : 0.5
        let xPos   = xFrac * geo.size.width
        let tipW: CGFloat = 140
        let clampedX = min(max(xPos - tipW / 2, 8), geo.size.width - tipW - 8)

        return VStack(alignment: .leading, spacing: 6) {
            Text(yearLabel(for: point.monthIndex))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.mist)
                .tracking(0.8)
                .textCase(.uppercase)

            HStack(spacing: 6) {
                Circle().fill(Color.sage).frame(width: 6, height: 6)
                Text(shortLabel(loan))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.ink)
                Text("debt")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.45))
            }

            if investingEnabled && invest > 0 {
                HStack(spacing: 6) {
                    Circle().fill(Color.gold).frame(width: 6, height: 6)
                    Text(shortLabel(invest))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.ink)
                    Text("wealth")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .frame(width: tipW)
        .position(x: clampedX + tipW / 2, y: 30)
    }

    // MARK: - X Axis Labels

    private var xAxisLabels: some View {
        HStack {
            if let first = series.first {
                Text(yearLabel(for: first.monthIndex))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.mist)
            }
            Spacer()
            // Mid point
            if series.count > 2 {
                Text(yearLabel(for: series[series.count / 2].monthIndex))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.mist)
            }
            Spacer()
            if let last = series.last {
                Text(yearLabel(for: last.monthIndex))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.mist)
            }
        }
    }

    // MARK: - Legend

    private func legendItem(color: Color, dashed: Bool, label: String) -> some View {
        HStack(spacing: 5) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(color)
                            .frame(width: 4, height: 2)
                            .cornerRadius(1)
                    }
                }
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 14, height: 2)
                    .cornerRadius(1)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.mist)
        }
    }

    // MARK: - Interaction

    private func updateSelection(x: CGFloat, width: CGFloat) {
        guard !series.isEmpty else { return }
        let fraction = max(0, min(1, x / width))
        let idx = Int(fraction * CGFloat(series.count - 1))
        if idx != selectedIndex {
            withAnimation(.easeOut(duration: 0.08)) {
                selectedIndex = idx
            }
            // Light haptic
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
        }
    }

    // MARK: - Label Helpers

    private func shortLabel(_ v: Double) -> String {
        let abs = Swift.abs(v)
        if abs >= 1_000_000 { return "$\(String(format: "%.1f", v / 1_000_000))M" }
        if abs >= 1_000     { return "$\(Int(v / 1_000))k" }
        return "$0"
    }

    private func yearLabel(for monthIndex: Int) -> String {
        let year  = Calendar.current.component(.year, from: Date()) + monthIndex / 12
        let month = Calendar.current.component(.month, from: Date()) + monthIndex % 12
        let clampedMonth = ((month - 1) % 12) + 1
        let date = Calendar.current.date(from: DateComponents(year: year, month: clampedMonth)) ?? Date()
        let f = DateFormatter()
        f.dateFormat = monthIndex % 12 == 0 ? "MMM ''yy" : "''yy"
        return f.string(from: date)
    }
}


