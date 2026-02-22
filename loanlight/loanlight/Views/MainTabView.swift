import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            PlanView()
                .tabItem {
                    Label("Plan", systemImage: "chart.line.uptrend.xyaxis")
                }

            LearnView()
                .tabItem {
                    Label("Learn", systemImage: "books.vertical")
                }
        }
        .tint(.sage)
    }
}
