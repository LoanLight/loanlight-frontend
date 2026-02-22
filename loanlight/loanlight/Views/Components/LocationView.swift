//
//  YourLocation.swift
//  loanlight
//
//  Created by Sruthy Mammen on 2/21/26.
//

import SwiftUI

// MARK: - Location Data Model (UI-only)

struct LocationData {
    var city: String = ""
    var state: String = ""           // 2-letter, e.g. "NY"
    var homeType: HomeType = .oneBed
    var estimatedRent: Double = 0
    var monthlyExpenses: Double = 0
    var isLoadingRent: Bool = false
    var rentError: String? = nil

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
}

// MARK: - LocationView

struct LocationView: View {

    var currentStep: Int = 6
    var totalSteps: Int  = 7
    var onContinue: (HousingIn?, Double) -> Void = { _, _ in }

    @State private var data = LocationData()

    private var canContinue: Bool {
        !data.city.isEmpty && data.state.count == 2 && !data.isLoadingRent
    }

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress Bar
                HStack(spacing: 4) {
                    ForEach(1...totalSteps, id: \.self) { step in
                        RoundedRectangle(cornerRadius: 2)
                            .frame(height: 3)
                            .foregroundColor(step <= currentStep ? .primary : Color(.systemGray5))
                    }
                }
                .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // Step pill
                        HStack(spacing: 6) {
                            Circle().frame(width: 6, height: 6).foregroundColor(.primary)
                            Text("STEP \(currentStep) OF \(totalSteps)")
                                .font(AppFont.chip).foregroundColor(.primary).tracked(.wide)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().stroke(Color.primary.opacity(0.3), lineWidth: 1))
                        .padding(.bottom, 14)

                        Text("Your Location")
                            .font(AppFont.serif(28)).foregroundColor(.primaryText).padding(.bottom, 8)

                        Text("We use HUD Fair Market Rent data to estimate your housing costs.")
                            .font(AppFont.body).foregroundColor(.secondaryText)
                            .lineSpacing(3).padding(.bottom, 24)

                        // City
                        Text("CITY")
                            .font(AppFont.sectionLabel).foregroundColor(.secondaryText)
                            .tracked(.wide).padding(.bottom, 8)

                        TextField("e.g. Boston", text: $data.city)
                            .font(AppFont.serif(22))
                            .padding(16)
                            .background(Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(!data.city.isEmpty ? Color.primary.opacity(0.5) : Color.cardBorder, lineWidth: 1))
                            .padding(.bottom, 16)

                        // State
                        Text("STATE (2-letter)")
                            .font(AppFont.sectionLabel).foregroundColor(.secondaryText)
                            .tracked(.wide).padding(.bottom, 8)

                        TextField("e.g. MA", text: $data.state)
                            .font(AppFont.serif(22))
                            .autocapitalization(.allCharacters)
                            .onChange(of: data.state) { val in
                                if val.count > 2 { data.state = String(val.prefix(2)) }
                            }
                            .padding(16)
                            .background(Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(data.state.count == 2 ? Color.primary.opacity(0.5) : Color.cardBorder, lineWidth: 1))
                            .padding(.bottom, 24)

                        // Home Type
                        Text("HOME TYPE")
                            .font(AppFont.sectionLabel).foregroundColor(.secondaryText)
                            .tracked(.wide).padding(.bottom, 12)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(HomeType.allCases, id: \.self) { type in
                                Button(action: {
                                    data.homeType = type
                                    if !data.city.isEmpty && data.state.count == 2 {
                                        Task { await fetchRentFromAPI() }
                                    }
                                }) {
                                    VStack(spacing: 10) {
                                        Text(type.emoji).font(.system(size: 32))
                                        Text(type.rawValue).font(AppFont.bodyMedium).foregroundColor(.primaryText)
                                    }
                                    .frame(maxWidth: .infinity).padding(.vertical, 20)
                                    .background(data.homeType == type ? Color.primaryTint : Color.cardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(data.homeType == type ? Color.primary : Color.cardBorder,
                                                lineWidth: data.homeType == type ? 1.5 : 1))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.bottom, 20)

                        // HUD Rent Card
                        if data.isLoadingRent {
                            HStack {
                                ProgressView().tint(.white)
                                Text("Fetching HUD rent estimate…")
                                    .font(AppFont.caption).foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.primary.opacity(0.8)))
                            .padding(.bottom, 24)
                        } else if data.estimatedRent > 0 {
                            hudCard.padding(.bottom, 24)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        if let err = data.rentError {
                            Text(err).font(AppFont.caption).foregroundColor(.danger)
                                .padding(.bottom, 16)
                        }

                        expensesSection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
                .animation(.easeInOut(duration: 0.25), value: data.estimatedRent)

                // Bottom button
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
                    .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 17)
                    .background(canContinue ? Color.primary : Color.subtleBg)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canContinue)
                .padding(.horizontal, 24).padding(.bottom, 36).padding(.top, 12)
            }
        }
    }

    // MARK: - HUD Card

    private var hudCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HUD FAIR MARKET RENT · \(data.city.uppercased()), \(data.state.uppercased())")
                .font(AppFont.tag).foregroundColor(.white.opacity(0.6)).tracked(.wider)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("$\(Int(data.estimatedRent).formatted())")
                    .font(AppFont.serif(42)).foregroundColor(.white)
                Text("/mo").font(AppFont.body).foregroundColor(.white.opacity(0.6))
            }

            Text("\(data.homeType.rawValue) · HUD FMR data")
                .font(AppFont.caption).foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(20)
        .background(RoundedRectangle(cornerRadius: 16)
            .fill(LinearGradient(colors: [Color.primary, Color.primary.opacity(0.7)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing)))
    }

    // MARK: - Expenses

    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MONTHLY EXPENSES (EXCLUDING RENT)")
                    .font(AppFont.sectionLabel).foregroundColor(.secondaryText).tracked(.wide)
                Text("Food, transport, subscriptions, etc.")
                    .font(AppFont.caption).foregroundColor(.secondaryText)
            }
            VStack(spacing: 14) {
                HStack {
                    Text("$0").font(AppFont.caption).foregroundColor(.secondaryText)
                    Spacer()
                    Text(data.monthlyExpenses == 0 ? "—" : "$\(Int(data.monthlyExpenses).formatted())/mo")
                        .font(AppFont.serif(22)).foregroundColor(.primary)
                        .animation(.easeInOut(duration: 0.1), value: data.monthlyExpenses)
                    Spacer()
                    Text("$5,000").font(AppFont.caption).foregroundColor(.secondaryText)
                }
                Slider(value: $data.monthlyExpenses, in: 0...5000, step: 50).tint(.primary)
            }
            .padding(16).background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(data.monthlyExpenses > 0 ? Color.primary.opacity(0.3) : Color.cardBorder, lineWidth: 1))
        }
        .padding(.bottom, 16)
    }

    // MARK: - API calls

    private func fetchRentFromAPI() async {
        guard let housingIn = data.toHousingIn() else { return }
        data.isLoadingRent = true
        data.rentError = nil

        do {
            let housingOut: HousingOut = try await APIClient.post(path: "/housing", body: housingIn)
            data.estimatedRent = Double(truncating: housingOut.hudEstimatedRentMonthly as NSDecimalNumber)
        } catch {
            data.rentError = "Could not fetch rent estimate. You can continue anyway."
        }
        data.isLoadingRent = false
    }

    private func fetchRentThenContinue() async {
        // Fetch if we haven't yet (or force refresh)
        if data.estimatedRent == 0 {
            await fetchRentFromAPI()
        }
        let housingIn = data.toHousingIn()
        onContinue(housingIn, data.monthlyExpenses)
    }
}

#Preview { LocationView() }
