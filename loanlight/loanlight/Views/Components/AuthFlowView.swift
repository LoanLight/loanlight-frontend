
import SwiftUI

struct AuthFlowView: View {
    var onAuthenticated: () -> Void = {}

    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            if viewModel.showSignUp {
                SignUpView(viewModel: viewModel)
                    .transition(.move(edge: .trailing))
            } else {
                SignInView(viewModel: viewModel)
                    .transition(.move(edge: .leading))
            }
        }
        .onAppear {
            viewModel.onAuthenticated = onAuthenticated
        }
        .background(Color.screenBg.ignoresSafeArea())
    }
}

// MARK: - Sign In View

struct SignInView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                heroHeader

                VStack(alignment: .leading, spacing: 0) {

                    Text("Welcome back")
                        .font(AppFont.serif(28))
                        .foregroundColor(.primaryText)
                        .padding(.bottom, 6)

                    Text("Sign in to continue to your plan")
                        .font(AppFont.body)
                        .foregroundColor(.secondaryText)
                        .padding(.bottom, 28)

                    // Email
                    fieldLabel("EMAIL")
                    AuthField(
                        placeholder: "your@email.com",
                        text: $viewModel.signInData.email,
                        keyboardType: .emailAddress,
                        isSecure: false
                    )
                    .padding(.bottom, 16)

                    // Password
                    fieldLabel("PASSWORD")
                    AuthField(
                        placeholder: "Password",
                        text: $viewModel.signInData.password,
                        isSecure: !viewModel.showSignInPassword,
                        trailingIcon: viewModel.showSignInPassword ? "eye.slash" : "eye",
                        onTrailingTap: { viewModel.showSignInPassword.toggle() }
                    )
                    .padding(.bottom, 8)

                    HStack {
                        Spacer()
                        Button("Forgot password?") {}
                            .font(AppFont.smallButton)
                            .foregroundColor(.secondaryText)
                    }
                    .padding(.bottom, 24)

                    // Error
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }

                    // Sign In Button
                    Button(action: viewModel.handleSignIn) {
                        primaryButtonContent("Sign In")
                    }
                    .disabled(!viewModel.isSignInValid || viewModel.isLoading)
                    .padding(.bottom, 16)

                    orDivider
                        .padding(.bottom, 16)

                    // Create Account
                    Button(action: viewModel.switchToSignUp) {
                        HStack(spacing: 8) {
                            Text("✦").foregroundColor(.accent)
                            Text("Create a free account")
                                .font(AppFont.ctaButton)
                                .foregroundColor(.primaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color.accentTint)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.accent.opacity(0.25), lineWidth: 1)
                        )
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 28)
                .padding(.top, 32)
                .background(Color.screenBg)
            }
        }
        .background(Color.screenBg.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.primary,
                    Color.primary.opacity(0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Orbit rings
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    Ellipse()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        .frame(
                            width: CGFloat(120 + i * 50),
                            height: CGFloat(60 + i * 25)
                        )
                        .rotationEffect(.degrees(Double(i) * 22))
                }
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Text("🎓").font(.system(size: 28))
                }
            }
            .offset(y: 20)

            // App name
            VStack(spacing: 6) {
                Text("LoanLight")
                    .padding(.top, 50)
                    .font(AppFont.serif(30))
                    .foregroundColor(.white)
                Text("Your student debt, finally made sense of.")
                    .font(AppFont.caption)
                    .foregroundColor(.white.opacity(0.75))
            }
            .offset(y: -70)
        }
        .frame(height: 280)
        .overlay(alignment: .bottom) {
            WaveShape()
                .fill(Color.screenBg)
                .frame(height: 40)
        }
    }

    // MARK: - Shared Sub-views

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(AppFont.sectionLabel)
            .foregroundColor(.secondaryText)
            .tracked(.wide)
            .padding(.bottom, 8)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 13))
            Text(message)
                .font(AppFont.caption)
        }
        .foregroundColor(.danger1)
        .padding(.bottom, 12)
    }

    private func primaryButtonContent(_ title: String) -> some View {
        Group {
            if viewModel.isLoading {
                ProgressView().scaleEffect(0.9).tint(.white)
            } else {
                Text(title).font(AppFont.ctaButton)
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 17)
        .background(viewModel.isSignInValid ? Color.primary : Color.subtleBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var orDivider: some View {
        HStack {
            Rectangle().frame(height: 1).foregroundColor(.divider)
            Text("or")
                .font(AppFont.caption)
                .foregroundColor(.secondaryText)
                .padding(.horizontal, 12)
            Rectangle().frame(height: 1).foregroundColor(.divider)
        }
    }
}

// MARK: - Sign Up View

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // Back button
                HStack {
                    Button(action: viewModel.switchToSignIn) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Sign In")
                                .font(AppFont.bodyMedium)
                        }
                        .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.top, 60)
                .padding(.bottom, 24)

                VStack(alignment: .leading, spacing: 0) {

                    Text("Create account")
                        .font(AppFont.serif(28))
                        .foregroundColor(.primaryText)
                        .padding(.bottom, 6)

                    Text("Start planning your path to debt freedom.")
                        .font(AppFont.body)
                        .foregroundColor(.secondaryText)
                        .padding(.bottom, 28)

                    // First + Last name
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("FIRST NAME")
                            AuthField(placeholder: "First", text: $viewModel.signUpData.firstName)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("LAST NAME")
                            AuthField(placeholder: "Last", text: $viewModel.signUpData.lastName)
                        }
                    }
                    .padding(.bottom, 16)

                    // Email
                    fieldLabel("EMAIL")
                    AuthField(
                        placeholder: "your@email.com",
                        text: $viewModel.signUpData.email,
                        keyboardType: .emailAddress,
                        isSecure: false
                    )
                    .padding(.bottom, 16)

                    // Password
                    fieldLabel("PASSWORD")
                    AuthField(
                        placeholder: "Min. 8 characters",
                        text: $viewModel.signUpData.password,
                        isSecure: !viewModel.showSignUpPassword,
                        trailingIcon: viewModel.showSignUpPassword ? "eye.slash" : "eye",
                        onTrailingTap: { viewModel.showSignUpPassword.toggle() }
                    )
                    .padding(.bottom, 8)

                    // Strength bar
                    if !viewModel.signUpData.password.isEmpty {
                        passwordStrengthBar.padding(.bottom, 16)
                    } else {
                        Spacer().frame(height: 16)
                    }

                    // Confirm Password
                    fieldLabel("CONFIRM PASSWORD")
                    ZStack(alignment: .trailing) {
                        AuthField(
                            placeholder: "Re-enter password",
                            text: $viewModel.signUpData.confirmPassword,
                            isSecure: !viewModel.showConfirmPassword,
                            trailingIcon: viewModel.showConfirmPassword ? "eye.slash" : "eye",
                            onTrailingTap: { viewModel.showConfirmPassword.toggle() }
                        )
                        if !viewModel.signUpData.confirmPassword.isEmpty {
                            Image(systemName: viewModel.passwordsMatch
                                  ? "checkmark.circle.fill"
                                  : "xmark.circle.fill")
                                .foregroundColor(viewModel.passwordsMatch ? .success1 : .danger1)
                                .padding(.trailing, 44)
                        }
                    }
                    .padding(.bottom, 24)

                    // Error
                    if let error = viewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle").font(.system(size: 13))
                            Text(error).font(AppFont.caption)
                        }
                        .foregroundColor(.danger1)
                        .padding(.bottom, 12)
                    }

                    // Sign Up Button
                    Button(action: viewModel.handleSignUp) {
                        Group {
                            if viewModel.isLoading {
                                ProgressView().scaleEffect(0.9).tint(.white)
                            } else {
                                Text("Create Account").font(AppFont.ctaButton)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(viewModel.isSignUpValid ? Color.primary : Color.subtleBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!viewModel.isSignUpValid || viewModel.isLoading)
                    .padding(.bottom, 16)

                    // Already have account
                    HStack {
                        Spacer()
                        Text("Already have an account? ")
                            .font(AppFont.body)
                            .foregroundColor(.secondaryText)
                        Button("Sign in", action: viewModel.switchToSignIn)
                            .font(AppFont.bodySemibold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 28)
            }
        }
        .background(Color.screenBg.ignoresSafeArea())
    }

    // MARK: - Password Strength Bar

    private var passwordStrengthBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .frame(height: 3)
                        .foregroundColor(
                            i < viewModel.passwordStrength
                            ? viewModel.strengthColor
                            : Color.divider
                        )
                }
            }
            Text(viewModel.strengthLabel)
                .font(AppFont.microBold)
                .foregroundColor(viewModel.strengthColor)
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(AppFont.sectionLabel)
            .foregroundColor(.secondaryText)
            .tracked(.wide)
            .padding(.bottom, 8)
    }
}

// MARK: - Reusable Auth Field

struct AuthField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var trailingIcon: String? = nil
    var onTrailingTap: (() -> Void)? = nil

    @FocusState private var focused: Bool

    var body: some View {
        HStack {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(AppFont.body)
                    .foregroundColor(.ink)
                    .focused($focused)
            } else {
                TextField(placeholder, text: $text)
                    .font(AppFont.body)
                    .foregroundColor(.ink)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focused)
            }

            if let icon = trailingIcon {
                Button(action: { onTrailingTap?() }) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    focused ? Color.primary.opacity(0.5) : Color.cardBorder,
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.15), value: focused)
    }
}

// MARK: - Wave Shape

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height),
            control1: CGPoint(x: rect.width * 0.25, y: 0),
            control2: CGPoint(x: rect.width * 0.75, y: 0)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

#Preview {
    AuthFlowView()
}
