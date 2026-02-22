//
//  YourLocation.swift
//  loanlight
//
//  Created by Sruthy Mammen on 2/21/26.
//

import SwiftUI

// MARK: - Location Data Model (UI-only)

struct LocationData {
    var zipCode: String = ""
    var homeType: HomeType = .studio
    var estimatedRent: Double = 0
    var city: String = ""
    var state: String = ""          // 2-letter, e.g. "NY"
    var monthlyExpenses: Double = 0

    /// Converts to the backend HousingIn model.
    /// Returns nil if city or state are missing.
    func toHousingIn() -> HousingIn? {
        guard !city.isEmpty, !state.isEmpty else { return nil }
        return HousingIn(
            city: city,
            state: state,
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

    /// Maps to the HousingIn bedroomCount field (0 = studio)
    var bedroomCount: Int {
        switch self {
        case .studio:    return 0
        case .oneBed:    return 1
        case .twoBed:    return 2
        case .threePlus: return 3
        }
    }

    func rentEstimate(for zip: String) -> Double {
        switch self {
        case .studio:    return 1_843
        case .oneBed:    return 2_100
        case .twoBed:    return 2_600
        case .threePlus: return 3_200
        }
    }
}

// MARK: - Location View

struct LocationView: View {

    var currentStep: Int = 4
    var totalSteps: Int  = 6
    /// Returns a HousingIn (backend model) and the raw monthly expenses to the parent.
    var onContinue: (HousingIn?, Double) -> Void = { _, _ in }

    @State private var data = LocationData()

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

                        Text("We use HUD Fair Market Rent data to estimate your housing costs.")
                            .font(AppFont.body)
                            .foregroundColor(.secondaryText)
                            .lineSpacing(3)
                            .padding(.bottom, 24)

                        // ── ZIP Code ──
                        Text("ZIP CODE")
                            .font(AppFont.sectionLabel)
                            .foregroundColor(.secondaryText)
                            .tracked(.wide)
                            .padding(.bottom, 8)

                        TextField("e.g. 10001", text: $data.zipCode)
                            .font(AppFont.serif(28))
                            .keyboardType(.numberPad)
                            .padding(16)
                            .background(Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        data.zipCode.count == 5
                                            ? Color.primary.opacity(0.5)
                                            : Color.cardBorder,
                                        lineWidth: 1
                                    )
                            )
                            .onChange(of: data.zipCode) { val in
                                if val.count > 5 { data.zipCode = String(val.prefix(5)) }
                                if val.count == 5 { updateRentEstimate() }
                            }
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
                                    updateRentEstimate()
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

                        // ── HUD Card ──
                        if data.estimatedRent > 0 {
                            hudCard
                                .padding(.bottom, 24)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
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
                    onContinue(data.toHousingIn(), data.monthlyExpenses)
                }) {
                    Text("Calculate My Plan")
                        .font(AppFont.ctaButton)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            data.zipCode.count == 5 ? Color.primary : Color.subtleBg
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(data.zipCode.count < 5)
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .padding(.top, 12)
            }
        }
    }

    // MARK: - HUD Card

    private var hudCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HUD FAIR MARKET RENT · \(data.city.isEmpty ? "ZIP \(data.zipCode)" : data.city.uppercased())")
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

            Text("\(data.homeType.rawValue) · ZIP \(data.zipCode) · 2024 FMR data")
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

    // MARK: - Expenses Slider

    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            VStack(alignment: .leading, spacing: 4) {
                Text("ESTIMATED MONTHLY EXPENSES DISCREPANCY")
                    .font(AppFont.sectionLabel)
                    .foregroundColor(.secondaryText)
                    .tracked(.wide)
                Text("How much do you spend monthly outside of rent?")
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

                if data.monthlyExpenses > 0 {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(AppFont.micro)
                            .foregroundColor(.primary)
                        Text("We'll factor this into your repayment plan budget")
                            .font(AppFont.micro)
                            .foregroundColor(.primary)
                    }
                    .transition(.opacity)
                }
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
            .animation(.easeInOut(duration: 0.2), value: data.monthlyExpenses > 0)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Rent Estimate

    private func updateRentEstimate() {
        guard data.zipCode.count == 5 else { return }
        withAnimation {
            data.estimatedRent = data.homeType.rentEstimate(for: data.zipCode)
            // TODO: replace with real reverse geocode API call
            data.city  = "New York"
            data.state = "NY"
        }
    }
}

#Preview {
    LocationView()
}
