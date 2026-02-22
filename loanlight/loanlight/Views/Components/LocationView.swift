//
//  YourLocation.swift
//  loanlight
//
//  Created by Sruthy Mammen on 2/21/26.
//

import SwiftUI
import CoreLocation

// MARK: - Location Data Model (UI-only)

struct LocationData {
    var city: String = ""
    var state: String = ""           // 2-letter, e.g. "NY"
    var zipCode: String = ""         // 5-digit ZIP (recommended for best results)
    var homeType: HomeType = .oneBed
    var estimatedRent: Double = 0
    var monthlyExpenses: Double = 0
    var isLoadingRent: Bool = false
    var rentError: String? = nil
    var rentSource: String? = nil

    func toHousingIn() -> HousingIn? {
        guard !city.isEmpty, state.count == 2 else { return nil }
        return HousingIn(
            city: city,
            state: state.uppercased(),
            bedroomCount: homeType.bedroomCount,
            housingType: "apartment"
        )
    }
}

enum HomeType: String, CaseIterable {
    case studio    = "Studio"
    case oneBed    = "1 Bedroom"
    case twoBed    = "2 Bedroom"
    case threePlus = "3+ Bedroom"

    var emoji: String {
        switch self {
        case .studio:    return "🏢"
        case .oneBed:    return "🛏"
        case .twoBed:    return "🏠"
        case .threePlus: return "🏡"
        }
    }

    var bedroomCount: Int {
        switch self {
        case .studio:    return 0
        case .oneBed:    return 1
        case .twoBed:    return 2
        case .threePlus: return 3
        }
    }

    /// Heuristic multiplier to scale "median gross rent (all units)" into bedroom-ish estimate
    var censusMultiplier: Double {
        switch self {
        case .studio:    return 0.85
        case .oneBed:    return 1.00
        case .twoBed:    return 1.25
        case .threePlus: return 1.55
        }
    }
}

// MARK: - LocationView

struct LocationView: View {

    var currentStep: Int = 6
    var totalSteps: Int  = 7
    var onContinue: (HousingIn?, Double) -> Void = { _, _ in }

    @State private var data = LocationData()

    // Cancel in-flight rent lookups when inputs change quickly
    @State private var rentTask: Task<Void, Never>?

    private var canContinue: Bool {
        !data.city.isEmpty && data.state.count == 2 && !data.isLoadingRent
    }

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Progress Bar ──
                HStack(spacing: 4) {
                    ForEach(1...totalSteps, id: \.self) { step in
                        RoundedRectangle(cornerRadius: 2)
                            .frame(height: 3)
                            .foregroundColor(step <= currentStep ? .primary : Color(.systemGray5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Step Pill ──
                        HStack(spacing: 6) {
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.primary)
                            Text("STEP \(currentStep) OF \(totalSteps)")
                                .font(AppFont.chip)
                                .foregroundColor(.primary)
                                .tracked(.wide)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().stroke(Color.primary.opacity(0.3), lineWidth: 1))
                        .padding(.bottom, 14)

                        // ── Title ──
                        Text("Your Location")
                            .font(AppFont.serif(28))
                            .foregroundColor(.primaryText)
                            .padding(.bottom, 8)

                        Text("We estimate rent using Census ACS median gross rent by ZIP, scaled by home type.")
                            .font(AppFont.body)
                            .foregroundColor(.secondaryText)
                            .lineSpacing(3)
                            .padding(.bottom, 24)

                        // ── City ──
                        Text("CITY")
                            .font(AppFont.sectionLabel)
                            .foregroundColor(.secondaryText)
                            .tracked(.wide)
                            .padding(.bottom, 8)

                        TextField("e.g. Boston", text: $data.city)
                            .font(AppFont.serif(22))
                            .foregroundColor(.ink)
                            .padding(16)
                            .background(Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(!data.city.isEmpty ? Color.primary.opacity(0.5) : Color.cardBorder, lineWidth: 1)
                            )
                            .padding(.bottom, 16)

                        // ── State ──
                        Text("STATE (2-letter)")
                            .font(AppFont.sectionLabel)
                            .foregroundColor(.secondaryText)
                            .tracked(.wide)
                            .padding(.bottom, 8)

                        TextField("e.g. MA", text: $data.state)
                            .font(AppFont.serif(22))
                            .foregroundColor(.ink)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: data.state) { val in
                                if val.count > 2 { data.state = String(val.prefix(2)) }
                            }
                            .padding(16)
                            .background(Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(data.state.count == 2 ? Color.primary.opacity(0.5) : Color.cardBorder, lineWidth: 1)
                            )
                            .padding(.bottom, 16)

                        // ── ZIP ──
                        Text("ZIP CODE")
                            .font(AppFont.sectionLabel)
                            .foregroundColor(.secondaryText)
                            .tracked(.wide)
                            .padding(.bottom, 8)

                        TextField("e.g. 02139", text: $data.zipCode)
                            .font(AppFont.serif(22))
                            .foregroundColor(.ink)

                            .keyboardType(.numberPad)
                            .onChange(of: data.zipCode) { val in
                                if val.count > 5 { data.zipCode = String(val.prefix(5)) }
                                if val.count == 5, !data.city.isEmpty, data.state.count == 2 {
                                    scheduleRentFetch()
                                }
                            }
                            .padding(16)
                            .background(Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(data.zipCode.count == 5 ? Color.primary.opacity(0.5) : Color.cardBorder, lineWidth: 1)
                            )
                            .padding(.bottom, 24)

                        // ── Home Type ──
                        Text("HOME TYPE")
                            .font(AppFont.sectionLabel)
                            .foregroundColor(.secondaryText)
                            .tracked(.wide)
                            .padding(.bottom, 12)

                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 12
                        ) {
                            ForEach(HomeType.allCases, id: \.self) { type in
                                Button(action: {
                                    data.homeType = type
                                    if !data.city.isEmpty, data.state.count == 2, data.zipCode.count == 5 {
                                        scheduleRentFetch()
                                    }
                                }) {
                                    VStack(spacing: 10) {
                                        Text(type.emoji)
                                            .font(.system(size: 32))
                                        Text(type.rawValue)
                                            .font(AppFont.bodyMedium)
                                            .foregroundColor(.primaryText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(data.homeType == type ? Color.primaryTint : Color.cardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                data.homeType == type ? Color.primary : Color.cardBorder,
                                                lineWidth: data.homeType == type ? 1.5 : 1
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.bottom, 20)

                        // ── Rent Card ──
                        if data.isLoadingRent {
                            HStack(spacing: 10) {
                                ProgressView().tint(.white)
                                Text("Fetching rent estimate…")
                                    .font(AppFont.caption)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.primary.opacity(0.8)))
                            .padding(.bottom, 24)
                        } else if data.estimatedRent > 0 {
                            rentCard
                                .padding(.bottom, 24)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        if let err = data.rentError {
                            Text(err)
                                .font(AppFont.caption)
                                .foregroundColor(.danger)
                                .padding(.bottom, 16)
                        }

                        // ── Expenses Slider ──
                        expensesSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
                .animation(.easeInOut(duration: 0.25), value: data.estimatedRent)

                // ── Bottom Button ──
                Button(action: {
                    Task { await fetchRentThenContinue() }
                }) {
                    HStack(spacing: 8) {
                        if data.isLoadingRent {
                            ProgressView().tint(.white)
                        } else {
                            Text("Calculate My Plan").font(AppFont.ctaButton)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(canContinue ? Color.primary : Color.subtleBg)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .padding(.top, 12)
            }
        }
        .onAppear {
            // If you want: auto-fetch when returning to screen with prefilled data
            if !data.city.isEmpty, data.state.count == 2, data.zipCode.count == 5, data.estimatedRent == 0 {
                scheduleRentFetch()
            }
        }
    }

    // MARK: - Rent Card

    private var rentCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RENT ESTIMATE · \(data.city.uppercased()), \(data.state.uppercased())")
                .font(AppFont.tag)
                .foregroundColor(.white.opacity(0.6))
                .tracked(.wider)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("$\(Int(data.estimatedRent).formatted())")
                    .font(AppFont.serif(42))
                    .foregroundColor(.white)
                Text("/mo")
                    .font(AppFont.body)
                    .foregroundColor(.white.opacity(0.6))
            }

            Text("\(data.homeType.rawValue) · \(data.zipCode.isEmpty ? "ZIP unknown" : "ZIP \(data.zipCode)") · \(data.rentSource ?? "Census ACS")")
                .font(AppFont.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.primary, Color.primary.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    // MARK: - Expenses

    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            VStack(alignment: .leading, spacing: 4) {
                Text("MONTHLY EXPENSES (EXCLUDING RENT)")
                    .font(AppFont.sectionLabel)
                    .foregroundColor(.secondaryText)
                    .tracked(.wide)
                Text("Food, transport, subscriptions, etc.")
                    .font(AppFont.caption)
                    .foregroundColor(.secondaryText)
            }

            VStack(spacing: 14) {
                HStack {
                    Text("$0")
                        .font(AppFont.caption)
                        .foregroundColor(.secondaryText)
                    Spacer()
                    Text(data.monthlyExpenses == 0
                         ? "—"
                         : "$\(Int(data.monthlyExpenses).formatted())/mo")
                        .font(AppFont.serif(22))
                        .foregroundColor(.primary)
                        .animation(.easeInOut(duration: 0.1), value: data.monthlyExpenses)
                    Spacer()
                    Text("$5,000")
                        .font(AppFont.caption)
                        .foregroundColor(.secondaryText)
                }

                Slider(value: $data.monthlyExpenses, in: 0...5000, step: 50)
                    .tint(.primary)
            }
            .padding(16)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        data.monthlyExpenses > 0 ? Color.primary.opacity(0.3) : Color.cardBorder,
                        lineWidth: 1
                    )
            )
        }
        .padding(.bottom, 16)
    }

    // MARK: - Rent Fetch (Census)

    private func scheduleRentFetch() {
        rentTask?.cancel()
        rentTask = Task {
            await fetchRentFromCensus()
        }
    }

    private func fetchRentFromCensus() async {
        guard data.zipCode.count == 5 else {
            await MainActor.run { data.rentError = "Enter a 5-digit ZIP to estimate rent." }
            return
        }

        let requestedZip = data.zipCode
        let requestedCity = data.city
        let requestedState = data.state.uppercased()
        let requestedHomeType = data.homeType

        await MainActor.run {
            data.isLoadingRent = true
            data.rentError = nil
            data.rentSource = nil
            data.estimatedRent = 0
        }

        do {
            let medianGrossRent = try await fetchCensusMedianGrossRent(zip: requestedZip)
            let estimate = medianGrossRent * requestedHomeType.censusMultiplier

            await MainActor.run {
                // Apply only if inputs didn’t change mid-request
                guard data.zipCode == requestedZip,
                      data.city == requestedCity,
                      data.state.uppercased() == requestedState,
                      data.homeType == requestedHomeType
                else { return }

                data.estimatedRent = estimate
                data.rentSource = "Census ACS (median gross rent)"
                data.isLoadingRent = false
            }
        } catch {
            await MainActor.run {
                data.rentError = "Could not fetch Census rent for ZIP \(requestedZip)."
                data.isLoadingRent = false
            }
        }
    }

    /// Census ACS 5-year API, variable B25064_001E = Median gross rent (dollars).
    /// Tries multiple years so it keeps working even if a year endpoint changes.
    private func fetchCensusMedianGrossRent(zip: String) async throws -> Double {
        let yearsToTry = ["2024", "2023", "2022", "2021", "2020"]

        for year in yearsToTry {
            let urlString =
                "https://api.census.gov/data/\(year)/acs/acs5?get=NAME,B25064_001E&for=zip%20code%20tabulation%20area:\(zip)"
            guard let url = URL(string: urlString) else { continue }

            do {
                let (data, resp) = try await URLSession.shared.data(from: url)
                guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { continue }

                let obj = try JSONSerialization.jsonObject(with: data)
                guard let rows = obj as? [[String]], rows.count >= 2 else { continue }

                let header = rows[0]
                let row = rows[1]

                guard let rentIdx = header.firstIndex(of: "B25064_001E"),
                      rentIdx < row.count,
                      let median = Double(row[rentIdx]),
                      median > 0
                else { continue }

                return median
            } catch {
                continue
            }
        }

        throw NSError(domain: "Census", code: 404, userInfo: [NSLocalizedDescriptionKey: "No Census rent found"])
    }

    // MARK: - Continue

    private func fetchRentThenContinue() async {
        if data.estimatedRent == 0, data.zipCode.count == 5 {
            await fetchRentFromCensus()
        }
        onContinue(data.toHousingIn(), data.monthlyExpenses)
    }
}

#Preview { LocationView() }
