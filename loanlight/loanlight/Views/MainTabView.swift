//
//  MainTabView.swift
//  loanlight
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var planVM: PlanViewModel

    var body: some View {
        TabView {
            PlanView(vm: planVM)
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
