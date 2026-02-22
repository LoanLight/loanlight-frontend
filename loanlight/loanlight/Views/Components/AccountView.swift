//
//  AccountView.swift
//  loanlight
//
//  Created by Upasana Lamsal on 2/22/26.
//
import SwiftUI

// MARK: - Profile Overview Models

struct ProfileOverviewLoans: Decodable {
    let totalDebt: Decimal
    let totalMinPayment: Decimal
    let federalCount: Int
    let privateCount: Int

    enum CodingKeys: String, CodingKey {
        case totalDebt       = "total_debt"
        case totalMinPayment = "total_min_payment"
        case federalCount    = "federal_count"
        case privateCount    = "private_count"
    }

    init(from decoder: Decoder) throws {
        let c            = try decoder.container(keyedBy: CodingKeys.self)
        totalDebt        = try c.decodeDecimalString(forKey: .totalDebt)
        totalMinPayment  = try c.decodeDecimalString(forKey: .totalMinPayment)
        federalCount     = try c.decode(Int.self, forKey: .federalCount)
        privateCount     = try c.decode(Int.self, forKey: .privateCount)
    }
}

struct ProfileOverviewCashflow: Decodable {
    let takeHomeMonthly: Decimal
    let rentMonthly: Decimal
    let nonRentEssentialsMonthly: Decimal?
    let discretionaryBeforeLoans: Decimal?
    let afterMinPayments: Decimal?

    enum CodingKeys: String, CodingKey {
        case takeHomeMonthly          = "take_home_monthly"
        case rentMonthly              = "rent_monthly"
        case nonRentEssentialsMonthly = "non_rent_essentials_monthly"
        case discretionaryBeforeLoans = "discretionary_before_loans"
        case afterMinPayments         = "after_min_payments"
    }

    init(from decoder: Decoder) throws {
        let c                    = try decoder.container(keyedBy: CodingKeys.self)
        takeHomeMonthly          = try c.decodeDecimalString(forKey: .takeHomeMonthly)
        rentMonthly              = try c.decodeDecimalString(forKey: .rentMonthly)
        nonRentEssentialsMonthly = try c.decodeDecimalStringIfPresent(forKey: .nonRentEssentialsMonthly)
        discretionaryBeforeLoans = try c.decodeDecimalStringIfPresent(forKey: .discretionaryBeforeLoans)
        afterMinPayments         = try c.decodeDecimalStringIfPresent(forKey: .afterMinPayments)
    }
}

struct ProfileOverviewJobOffer: Decodable {
    let id: UUID
    let baseSalary: Decimal
    let bonus: Decimal?
    let state: String
    let estimatedTakeHomeMonthly: Decimal

    enum CodingKeys: String, CodingKey {
        case id
        case baseSalary               = "base_salary"
        case bonus
        case state
        case estimatedTakeHomeMonthly = "estimated_take_home_monthly"
    }

    init(from decoder: Decoder) throws {
        let c                    = try decoder.container(keyedBy: CodingKeys.self)
        id                       = try c.decode(UUID.self, forKey: .id)
        baseSalary               = try c.decodeDecimalString(forKey: .baseSalary)
        bonus                    = try c.decodeDecimalStringIfPresent(forKey: .bonus)
        state                    = try c.decode(String.self, forKey: .state)
        estimatedTakeHomeMonthly = try c.decodeDecimalString(forKey: .estimatedTakeHomeMonthly)
    }
}

struct ProfileOverviewHousing: Decodable {
    let id: UUID
    let city: String
    let state: String
    let bedroomCount: Int
    let housingType: String
    let hudEstimatedRentMonthly: Decimal

    enum CodingKeys: String, CodingKey {
        case id
        case city
        case state
        case bedroomCount            = "bedroom_count"
        case housingType             = "housing_type"
        case hudEstimatedRentMonthly = "hud_estimated_rent_monthly"
    }

    init(from decoder: Decoder) throws {
        let c                   = try decoder.container(keyedBy: CodingKeys.self)
        id                      = try c.decode(UUID.self, forKey: .id)
        city                    = try c.decode(String.self, forKey: .city)
        state                   = try c.decode(String.self, forKey: .state)
        bedroomCount            = try c.decode(Int.self, forKey: .bedroomCount)
        housingType             = try c.decode(String.self, forKey: .housingType)
        hudEstimatedRentMonthly = try c.decodeDecimalString(forKey: .hudEstimatedRentMonthly)
    }
}

struct ProfileOverviewResponse: Decodable {
    let jobOffer: ProfileOverviewJobOffer?
    let housing: ProfileOverviewHousing?
    let loans: ProfileOverviewLoans?
    let cashflowBaseline: ProfileOverviewCashflow?

    enum CodingKeys: String, CodingKey {
        case jobOffer         = "job_offer"
        case housing
        case loans
        case cashflowBaseline = "cashflow_baseline"
    }
}

// MARK: - AccountView

struct AccountView: View {
    let onLogout: () -> Void

    @State private var overview: ProfileOverviewResponse? = nil
    @State private var userEmail: String? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var showLogoutConfirm = false

    private var username: String {
        guard let email = userEmail else { return "" }
        return String(email.split(separator: "@").first ?? "")
    }

    private let currencyFmt: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        return f
    }()

    private let currencyFmtCents: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f
    }()

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // ── Header ─────────────────────────────────────────
                    headerSection
                        .padding(.top, 8)

                    if isLoading {
                        skeletonSection
                    } else if let overview = overview {
                        // ── Income ────────────────────────────────────
                        sectionLabel("Income")
                        if let job = overview.jobOffer {
                            incomeCard(job)
                        }

                        // ── Housing ───────────────────────────────────
                        sectionLabel("Housing")
                        if let housing = overview.housing {
                            housingCard(housing)
                        }

                        // ── Loans ─────────────────────────────────────
                        sectionLabel("Loans")
                        if let loans = overview.loans {
                            loansCard(loans)
                        }

                        // ── Monthly Cashflow ──────────────────────────
                        sectionLabel("Monthly Cashflow")
                        if let cashflow = overview.cashflowBaseline {
                            cashflowCard(cashflow, job: overview.jobOffer)
                        }

                        Spacer().frame(height: 32)
                    } else if let error = errorMessage {
                        errorView(error)
                    }

                    // ── Logout ────────────────────────────────────────
                    logoutButton
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                }
            }
            .refreshable { await loadOverview() }
        }
        .task { await loadOverview() }
        .confirmationDialog("Log out of LoanLight?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) { logout() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Group {
                    if !username.isEmpty {
                        Text("Hi, \(username) 👋")
                    } else {
                        Text("Account")
                    }
                }
                .font(.system(size: 32, weight: .bold, design: .default))
                .foregroundColor(.ink)

                if let email = userEmail {
                    Text(email)
                        .font(AppFont.caption)
                        .foregroundColor(.mist)
                }
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.sage.opacity(0.18))
                    .frame(width: 48, height: 48)
                Text(username.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.sage)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Income Card

    private func incomeCard(_ job: ProfileOverviewJobOffer) -> some View {
        VStack(spacing: 0) {
            statRow(
                label: "Base Salary",
                value: formatCurrency(job.baseSalary, cents: false),
                accent: false
            )
            dividerLine
            if let bonus = job.bonus, bonus > 0 {
                statRow(label: "Bonus", value: formatCurrency(bonus, cents: false), accent: false)
                dividerLine
            }
            statRow(
                label: "Take-Home / mo",
                value: formatCurrency(job.estimatedTakeHomeMonthly, cents: true),
                accent: true
            )
        }
        .cardStyle()
        .padding(.horizontal, 20)
    }

    // MARK: - Housing Card

    private func housingCard(_ h: ProfileOverviewHousing) -> some View {
        VStack(spacing: 0) {
            statRow(label: "Location", value: "\(h.city), \(h.state)", accent: false)
            dividerLine
            statRow(
                label: "\(h.bedroomCount == 0 ? "Studio" : "\(h.bedroomCount)BR") \(h.housingType.capitalized)",
                value: formatCurrency(h.hudEstimatedRentMonthly, cents: true) + "/mo",
                accent: true
            )
        }
        .cardStyle()
        .padding(.horizontal, 20)
    }

    // MARK: - Loans Card

    private func loansCard(_ loans: ProfileOverviewLoans) -> some View {
        VStack(spacing: 0) {
            statRow(label: "Total Debt", value: formatCurrency(loans.totalDebt, cents: true), accent: false)
            dividerLine
            statRow(label: "Min Payment / mo", value: formatCurrency(loans.totalMinPayment, cents: true), accent: false)
            dividerLine
            HStack {
                Text("Loan Count")
                    .font(AppFont.body)
                    .foregroundColor(.mist)
                Spacer()
                HStack(spacing: 8) {
                    if loans.federalCount > 0 {
                        loanBadge("\(loans.federalCount) Federal", color: .sage)
                    }
                    if loans.privateCount > 0 {
                        loanBadge("\(loans.privateCount) Private", color: .gold)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .cardStyle()
        .padding(.horizontal, 20)
    }

    // MARK: - Cashflow Card

    private func cashflowCard(_ cf: ProfileOverviewCashflow, job: ProfileOverviewJobOffer?) -> some View {
        let takeHome = cf.takeHomeMonthly
        let rent = cf.rentMonthly
        let remaining = takeHome - rent

        return VStack(spacing: 0) {
            cashflowRow(
                icon: "💰",
                label: "Take-Home",
                value: formatCurrency(takeHome, cents: true),
                isPositive: true
            )
            dividerLine
            cashflowRow(
                icon: "🏠",
                label: "Rent",
                value: "− " + formatCurrency(rent, cents: true),
                isPositive: false
            )
            dividerLine
            HStack {
                HStack(spacing: 8) {
                    Text("📊")
                    Text("After Rent")
                        .font(AppFont.body)
                        .foregroundColor(.ink)
                }
                Spacer()
                Text(formatCurrency(remaining, cents: true))
                    .font(AppFont.body.bold())
                    .foregroundColor(remaining > 0 ? .sage : .red)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .cardStyle()
        .padding(.horizontal, 20)
    }

    // MARK: - Logout Button

    private var logoutButton: some View {
        Button(action: { showLogoutConfirm = true }) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .medium))
                Text("Log Out")
                    .font(AppFont.body.weight(.medium))
            }
            .foregroundColor(.red.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.07))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.red.opacity(0.15), lineWidth: 1)
            )
        }
    }

    // MARK: - Skeleton

    private var skeletonSection: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.surface)
                    .frame(height: 100)
                    .shimmer()
                    .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Error View

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32)).foregroundColor(.mist)
            Text(msg)
                .font(AppFont.body).foregroundColor(.mist)
                .multilineTextAlignment(.center)
            Button("Retry") { Task { await loadOverview() } }
                .font(AppFont.body.weight(.medium))
                .foregroundColor(.sage)
        }
        .padding(40)
    }

    // MARK: - Helpers

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

    private func statRow(label: String, value: String, accent: Bool) -> some View {
        HStack {
            Text(label)
                .font(AppFont.body)
                .foregroundColor(.mist)
            Spacer()
            Text(value)
                .font(accent ? AppFont.body.bold() : AppFont.body)
                .foregroundColor(accent ? .ink : .ink.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func cashflowRow(icon: String, label: String, value: String, isPositive: Bool) -> some View {
        HStack {
            HStack(spacing: 8) {
                Text(icon)
                Text(label)
                    .font(AppFont.body)
                    .foregroundColor(.ink)
            }
            Spacer()
            Text(value)
                .font(AppFont.body)
                .foregroundColor(isPositive ? .ink.opacity(0.7) : .mist)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func loanBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppFont.captionBold)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(8)
    }

    private var dividerLine: some View {
        Divider()
            .background(Color.border)
            .padding(.horizontal, 16)
    }

    private func formatCurrency(_ value: Decimal, cents: Bool) -> String {
        let fmt = cents ? currencyFmtCents : currencyFmt
        return fmt.string(from: NSDecimalNumber(decimal: value)) ?? "$—"
    }

    // MARK: - Data

    private func loadOverview() async {
        isLoading = true
        errorMessage = nil
        do {
            // Fetch both in parallel
            async let overviewTask: ProfileOverviewResponse = APIClient.get(path: "/profile/overview")
            async let meTask: AccountResponse = APIClient.get(path: "/auth/me")
            let (fetchedOverview, me) = try await (overviewTask, meTask)
            await MainActor.run {
                self.overview   = fetchedOverview
                self.userEmail  = me.email
                self.isLoading  = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                self.isLoading    = false
            }
        }
    }

    private func logout() {
        TokenStore.clearToken()
        onLogout()
    }
}

// MARK: - Card Style Modifier

extension View {
    func cardStyle() -> some View {
        self
            .background(Color.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.border, lineWidth: 1)
            )
    }
}

#Preview {
    AccountView(onLogout: {})
}
