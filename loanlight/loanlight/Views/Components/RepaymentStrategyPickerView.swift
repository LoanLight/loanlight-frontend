import SwiftUI

struct RepaymentStrategyPickerView: View {
    @Binding var selected: RepaymentStrategy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repayment Strategy")
                .font(AppFont.sectionLabel)
                .tracking(1.0)
                .textCase(.uppercase)
                .foregroundColor(.mist)
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                ForEach(RepaymentStrategy.allCases) { strategy in
                    StrategyRowView(
                        strategy: strategy,
                        isSelected: selected == strategy,
                        onTap: { withAnimation(.easeInOut(duration: 0.18)) { selected = strategy } }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Single Row

private struct StrategyRowView: View {
    let strategy: RepaymentStrategy
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Radio
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.sage : Color.border, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle().fill(Color.sage).frame(width: 20, height: 20)
                        Circle().fill(Color.white).frame(width: 8, height: 8)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(strategy.displayName)
                        .font(AppFont.bodySemibold)
                        .foregroundColor(.ink)
                    Text(strategy.subtitle)
                        .font(AppFont.caption)
                        .foregroundColor(.mist)
                }

                Spacer()

                // Tag
                Text(strategy.tag)
                    .font(AppFont.tag)
                    .foregroundColor(strategy.tagForeground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(strategy.tagBackground)
                    .cornerRadius(6)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(isSelected ? Color.sagemist : Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.sage : Color.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - RepaymentStrategy display helpers
// (These map to your backend Literal type)

extension RepaymentStrategy {

    var tag: String {
        switch self {
        case .avalanche: return "Saves most $"
        case .snowball:  return "Motivating"
        case .hybrid:    return "Flexible"
        }
    }

    var tagForeground: Color {
        switch self {
        case .avalanche: return .sage
        case .snowball:  return Color(hex: "#8a6d1e")
        case .hybrid:    return .gold
        }
    }

    var tagBackground: Color {
        switch self {
        case .avalanche: return .sagetint
        case .snowball:  return .goldwash
        case .hybrid:    return .goldwash
        }
    }
}
