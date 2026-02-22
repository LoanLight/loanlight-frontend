//
//  MainTabView.swift
//  loanlight
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var planVM: PlanViewModel
    let onLogout: () -> Void

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            PlanView(vm: planVM)
                .tabItem {
                    Label("Plan", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)

            LearnView(investingEnabled: planVM.investingEnabled, selectedTab: $selectedTab)
                .tabItem {
                    Label("Learn", systemImage: "books.vertical")
                }
                .tag(1)

            AccountView(onLogout: onLogout)
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }
                .tag(2)
        }
        .tint(.sage)
    }
}
