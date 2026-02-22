import SwiftUI

/// Shows backend warnings (e.g. "commitment below minimum") in a dismissible banner.
struct WarningsBannerView: View {
    let warnings: [String]
    @State private var dismissed = false

    var body: some View {
        if !warnings.isEmpty && !dismissed {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.gold)
                    Text("Heads up")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.ink)
                    Spacer()
                    Button(action: { withAnimation { dismissed = true } }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.mist)
                    }
                }

                ForEach(warnings, id: \.self) { warning in
                    HStack(alignment: .top, spacing: 6) {
                        Circle()
                            .fill(Color.gold)
                            .frame(width: 4, height: 4)
                            .padding(.top, 5)
                        Text(warning)
                            .font(AppFont.caption)
                            .foregroundColor(.mist)
                    }
                }
            }
            .padding(14)
            .background(Color.goldwash)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gold.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .onChange(of: warnings) { _ in dismissed = false }
        }
    }
}
