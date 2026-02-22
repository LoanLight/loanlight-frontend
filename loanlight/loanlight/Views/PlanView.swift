import SwiftUI

struct PlanView: View {
    @StateObject private var vm = PlanViewModel()

    // Shared formatter helpers
    private static let currencyStyle = Decimal.FormatStyle.Currency(code: "USD")

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.paper.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // ── 1. Graph ─────────
                    HeroChartView(
                        series: vm.chartSeries,
                        investingEnabled: vm.investingEnabled,
                        freedomDate: vm.freedomDateFormatted,
                        monthsToFreedom: vm.planResponse?.monthsToFreedom ?? 0
                    )

                    // ── Warnings (if any from backend) ────────────
                    if let response = vm.planResponse, !response.warnings.isEmpty {
                        WarningsBannerView(warnings: response.warnings)
                            .padding(.top, 16)
                    }

                    

                    // ── 2. Investing toggle ────────────────────────
                    sectionLabel("Strategy")
                    InvestingToggleView(
                        investingEnabled: $vm.investingEnabled,
                        riskLevel: $vm.riskLevel
                    )
                    .onChange(of: vm.investingEnabled) { _ in triggerRecalculate() }
                    .onChange(of: vm.riskLevel) { _ in triggerRecalculate() }

                    // ── 3. Payment / Investment slider ─────────────
                    sectionLabel(vm.investingEnabled ? "Monthly Investment" : "Monthly Payment")
                    PaymentSliderView(
                        investingEnabled: vm.investingEnabled,
                        monthlyCommitment: $vm.monthlyCommitment,
                        sliderMin: vm.sliderMin,
                        sliderMax: vm.sliderMax,
                        monthlyInvestment: $vm.monthlyInvestmentAmount,
                        maxInvestment: vm.maxInvestmentAmount,
                        minimumLoanPayment: vm.planResponse?.cashflow.minimumLoanPayments ?? 0
                    )
                    .onChange(of: vm.monthlyCommitment) { _ in triggerRecalculate() }
                    .onChange(of: vm.monthlyInvestmentAmount) { _ in triggerRecalculate() }

                    

                    // ── 4. Repayment strategy ──────────────────────
                    RepaymentStrategyPickerView(selected: $vm.repaymentStrategy)
                        .onChange(of: vm.repaymentStrategy) { _ in triggerRecalculate() }

                    divider
                    
                    // ── 5. Cashflow breakdown ──────────────────────
                    sectionLabel("Your Money")
                    CashflowHeaderView(
                        takeHome: vm.jobOffer?.estimatedTakeHomeMonthly ?? 0,
                        rent: vm.housing?.hudEstimatedRentMonthly ?? 0,
                        expenses: $vm.monthlyExpenses,
                        available: vm.availableForLoansAndInvesting
                    )
                    .onChange(of: vm.monthlyExpenses) { _ in
                        triggerRecalculate()
                    }

                    // ── 6. Results grid ────────────────────────────
                    sectionLabel("Results")
                    if let response = vm.planResponse {
                        PlanResultsView(
                            response: response,
                            investingEnabled: vm.investingEnabled
                        )
                    } else {
                        resultsSkeletonView
                    }

                    // ── Save CTA ───────────────────────────────────
                    savePlanView
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    Spacer().frame(height: 110)
                }
            }
            .refreshable { await vm.recalculate() }

            // ── Loading overlay ────────────────────────────────
            if vm.isLoading {
                loadingBanner
            }

        }
        .task { await vm.recalculate() }
        .alert("Something went wrong", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("Retry") { Task { await vm.recalculate() } }
            Button("Dismiss", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your Plan")
                    .font(AppFont.serif(24))
                    .foregroundColor(.ink)
                if let job = vm.jobOffer {
                    Text(job.baseSalary.formatted(.currency(code: "USD").precision(.fractionLength(0))) + " · \(job.state)")
                        .font(AppFont.caption)
                        .foregroundColor(.mist)
                }
            }
            Spacer()

            // Mode badge — changes colour based on investing toggle
            HStack(spacing: 5) {
                Circle()
                    .fill(vm.investingEnabled ? Color.gold : Color.sage)
                    .frame(width: 6, height: 6)
                Text(vm.investingEnabled ? "Investing" : "Debt First")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(vm.investingEnabled ? .gold : .sage)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(vm.investingEnabled ? Color.goldwash : Color.sagetint)
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.2), value: vm.investingEnabled)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    // MARK: - Section Label

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(AppFont.sectionLabel)
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundColor(.mist)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)
    }

    // MARK: - Divider

    private var divider: some View {
        Divider()
            .background(Color.border)
            .padding(.horizontal, 20)
            .padding(.top, 16)
    }

    // MARK: - Results Skeleton (while loading)

    private var resultsSkeletonView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.surface)
                    .frame(height: 88)
                    .shimmer()
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Save CTA

    @State private var saved = false

    private var savePlanView: some View {
        VStack(spacing: 8) {
            Button(action: {
                withAnimation { saved = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { saved = false }
                }
            }) {
                HStack(spacing: 8) {
                    Text("✦").font(.system(size: 14))
                    Text("Save This Plan")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    vm.investingEnabled
                        ? LinearGradient(colors: [.gold, Color(hex: "#3a6a9a")],
                                         startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [.sage, Color(hex: "#2d5248")],
                                         startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
            }

            if saved {
                HStack(spacing: 6) {
                    Circle()
                        .fill(vm.investingEnabled ? Color.gold : Color.sage)
                        .frame(width: 6, height: 6)
                    Text("Plan saved")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(vm.investingEnabled ? .gold : .sage)
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Loading Banner

    private var loadingBanner: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                ProgressView().tint(.white).scaleEffect(0.85)
                Text("Recalculating…")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.ink.opacity(0.88))
            .cornerRadius(14)
            .padding(.bottom, 100)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Recalculate debounced

    @State private var recalcTask: Task<Void, Never>? = nil

    private func triggerRecalculate() {
        recalcTask?.cancel()
        recalcTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000) // 400ms debounce
            guard !Task.isCancelled else { return }
            await vm.recalculate()
        }
    }
}

// MARK: - Shimmer effect for skeleton loader

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: phase - 0.3),
                        .init(color: .white.opacity(0.45), location: phase),
                        .init(color: .clear, location: phase + 0.3),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

// MARK: - Preview

#Preview {
    PlanView()
}
