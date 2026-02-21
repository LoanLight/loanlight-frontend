import SwiftUI

/// The card that lets users flip between "Debt First" and "Investing On" modes.
/// When investing is off — emphasises debt elimination.
/// When investing is on — emphasises wealth building.
struct InvestingToggleView: View {
    @Binding var investingEnabled: Bool
    @Binding var riskLevel: RiskLevel

    var body: some View {
        VStack(spacing: 0) {
            // ── Main toggle row ────────────────────────────────
            HStack(spacing: 14) {
                // Icon changes based on mode
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(investingEnabled ? Color.goldwash : Color.sagetint)
                        .frame(width: 44, height: 44)
                    Text(investingEnabled ? "📈" : "🏔")
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(investingEnabled ? "Investing On" : "Debt Elimination")
                        .font(AppFont.bodySemibold)
                        .foregroundColor(.ink)
                    Text(investingEnabled
                         ? "Pay minimums · grow wealth now"
                         : "Every extra dollar crushes debt")
                        .font(AppFont.caption)
                        .foregroundColor(.mist)
                }

                Spacer()

                Toggle("", isOn: $investingEnabled.animation(.easeInOut(duration: 0.25)))
                    .toggleStyle(SwitchToggleStyle(tint: .gold))
                    .labelsHidden()
            }
            .padding(16)

            // ── Risk level picker (only when investing on) ─────
            if investingEnabled {
                Divider().background(Color.border).padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Investment Strategy")
                        .font(AppFont.sectionLabel)
                        .tracking(1.0)
                        .textCase(.uppercase)
                        .foregroundColor(.mist)

                    HStack(spacing: 8) {
                        ForEach(RiskLevel.allCases) { level in
                            RiskPillView(level: level, isSelected: riskLevel == level) {
                                withAnimation(.easeInOut(duration: 0.18)) { riskLevel = level }
                            }
                        }
                    }

                    // Expected return hint
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(.mist)
                        Text(riskLevel.expectedReturnLabel)
                            .font(.system(size: 11))
                            .foregroundColor(.mist)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // ── Mode emphasis banner ───────────────────────────
            HStack(spacing: 8) {
                Image(systemName: investingEnabled ? "chart.line.uptrend.xyaxis" : "checkmark.seal.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(investingEnabled ? .gold : .sage)
                Text(investingEnabled
                     ? "Investing from month one · loans paid at minimum"
                     : "Prioritising debt freedom · investing starts after payoff")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(investingEnabled ? .gold : .sage)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(investingEnabled ? Color.goldwash : Color.sagetint)
        }
        .background(Color.white)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.border, lineWidth: 1))
        .padding(.horizontal, 20)
    }
}

// MARK: - Risk Pill

private struct RiskPillView: View {
    let level: RiskLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(level.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .gold : .mist)
                Text(level.returnShort)
                    .font(.system(size: 9))
                    .foregroundColor(isSelected ? Color.gold.opacity(0.7) : Color.mist.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.goldwash : Color.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.gold : Color.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - RiskLevel helper

extension RiskLevel {
    var returnShort: String {
        switch self {
        case .low:      return "~4%"
        case .moderate: return "~7%"
        case .high:     return "~10%"
        }
    }
}
