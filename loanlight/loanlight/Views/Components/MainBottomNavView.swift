import SwiftUI

struct MainBottomNavView: View {
    private struct Tab {
        let icon: String
        let activeIcon: String
        let label: String
        let isActive: Bool
    }

    private let tabs: [Tab] = [
        Tab(icon: "chart.bar",       activeIcon: "chart.bar.fill",       label: "Dashboard", isActive: false),
        Tab(icon: "rectangle.stack", activeIcon: "rectangle.stack.fill", label: "Plan",      isActive: true),
        Tab(icon: "creditcard",      activeIcon: "creditcard.fill",       label: "Loans",     isActive: false),
        Tab(icon: "gearshape",       activeIcon: "gearshape.fill",        label: "Settings",  isActive: false),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.label) { tab in
                VStack(spacing: 4) {
                    Image(systemName: tab.isActive ? tab.activeIcon : tab.icon)
                        .font(.system(size: 20))
                        .foregroundColor(tab.isActive ? .sage : .mist)
                    Text(tab.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(tab.isActive ? .sage : .mist)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 16)
        .background(.ultraThinMaterial)
        .overlay(Divider().background(Color.border), alignment: .top)
    }
}
