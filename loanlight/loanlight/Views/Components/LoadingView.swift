//
//  Loading.swift
//  loanlight
//
//  Created by Sruthy Mammen on 2/21/26.
//

import SwiftUI

struct LoadingStep: Identifiable {
    let id = UUID()
    let label: String
    var isDone: Bool = false
}

struct PlanLoadingView: View {

    var onComplete: () -> Void = {}

    @State private var steps: [LoadingStep] = [
        LoadingStep(label: "Loaded federal + private loans"),
        LoadingStep(label: "Applying income & housing data"),
        LoadingStep(label: "Running IDR vs Standard vs Avalanche"),
        LoadingStep(label: "Selecting Balanced + Moderate strategy…"),
    ]
    @State private var currentStep = 0
    @State private var isFinished = false

    var body: some View {
    ZStack {
    Color.screenBg.ignoresSafeArea()

    VStack(spacing: 0) {
    Spacer()

        // ── Spinner / Checkmark ──
        ZStack {
    Circle()
                        .stroke(Color.divider, lineWidth: 3)
                        .frame(width: 72, height: 72)

    if !isFinished {
    Circle()
                            .trim(from: 0, to: 0.22)
                            .stroke(Color.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 72, height: 72)
                            .rotationEffect(.degrees(-90))
                            .animation(
    .linear(duration: 0.9).repeatForever(autoreverses: false),
value: isFinished
)
                            .rotationEffect(isFinished ? .degrees(0) : .degrees(360))
    } else {
        Image(systemName: "checkmark")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.accent)
                            .transition(.scale.combined(with: .opacity))
    }
        }
                .padding(.bottom, 40)

        // ── Headline ──
        Text("Building your\nplan…")
                    .font(AppFont.serif(32))
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 14)

        Text("We're running repayment scenarios,\ncost estimates, and risk analysis.")
                    .font(AppFont.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.bottom, 48)

        // ── Steps List ──
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(spacing: 14) {
    ZStack {
    Circle()
                                    .fill(step.isDone ? Color.primaryText : Color.subtleBg)
                                    .frame(width: 30, height: 30)
    Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(step.isDone ? Color.accent : Color.secondaryText)
    }

                    Text(step.label)
                                .font(step.isDone ? AppFont.bodyMedium : AppFont.body)
                                .foregroundColor(step.isDone ? .primaryText : .secondaryText)

                    Spacer()
                }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .opacity(step.isDone ? 1.0 : 0.4)
                        .animation(.easeInOut(duration: 0.3), value: step.isDone)

                        if index < steps.count - 1 {
                            Divider()
                                .padding(.leading, 76)
}
            }
}

        Spacer()
    }
}
        .onAppear { startSequence() }
    }

    private func startSequence() {
    for i in 0..<steps.count {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.8) {
            withAnimation { steps[i].isDone = true }
            if i == steps.count - 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
    withAnimation { isFinished = true }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        onComplete()
    }
}
}
}
    }
}
}
