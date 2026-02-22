//
//  File.swift
//  loanlight
//
//  Created by Upasana Lamsal on 2/22/26.
//

import SwiftUI

struct FirstLoadingView: View {
    // MARK: - State
    @State private var isLit: Bool = false
    @State private var bounceOffset: CGFloat = 0
    @State private var glowOpacity: Double = 0
    @State private var navigateToSignUp: Bool = false
    @State private var fadeOut: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.980, green: 0.980, blue: 0.973)
                    .ignoresSafeArea()

                GeometryReader { geo in
                    ZStack {
                        // Glow halo
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        (isLit ? Color(red: 0.239, green: 0.420, blue: 0.369) : Color(red: 0.788, green: 0.659, blue: 0.298)).opacity(0.55),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 400, height: 400)
                            .opacity(glowOpacity)
                            .blur(radius: 30)
                            .animation(.easeInOut(duration: 0.4), value: isLit)

                        // Start on yellow, transition to blue
                        Image(isLit ? "bulb_blue" : "bulb_yellow")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 280, height: 280)
                            .offset(y: bounceOffset)
                            .shadow(
                                color: isLit ? Color(red: 0.239, green: 0.420, blue: 0.369).opacity(0.8) : Color(red: 0.788, green: 0.659, blue: 0.298).opacity(0.6),
                                radius: isLit ? 36 : 12
                            )
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .opacity(fadeOut ? 0 : 1)
            }
            .navigationDestination(isPresented: $navigateToSignUp) {
                FederalLoansView()
            }
        }
        .onAppear {
            runAnimation()
        }
    }

    // MARK: - Animation Sequence
    private func runAnimation() {
        // 1. Blue bulb gently bounces (idle feel)
        withAnimation(.interpolatingSpring(stiffness: 200, damping: 8).repeatCount(2, autoreverses: true)) {
            bounceOffset = -14
        }

        // 2. After 1.2s — big bounce up then switch to yellow
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
                bounceOffset = -36
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                // Swap to yellow bulb at the peak of the jump
                withAnimation(.easeIn(duration: 0.15)) {
                    isLit = true
                }
                withAnimation(.easeOut(duration: 0.7)) {
                    glowOpacity = 1.0
                }
                // Land back down with a small secondary bounce
                withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.08)) {
                    bounceOffset = 0
                }
            }
        }

        // 3. Brief hold → fade out → navigate to SignUp
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.55)) {
                fadeOut = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                navigateToSignUp = true
            }
        }
    }
}
