import Foundation
import Combine
import SwiftUI

// MARK: - UI-only form state

struct SignInFormData {
    var email: String = ""
    var password: String = ""
}

struct SignUpFormData {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
}

// MARK: - ViewModel

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var showSignUp: Bool = false
    @Published var signInData = SignInFormData()
    @Published var signUpData = SignUpFormData()

    @Published var showSignInPassword: Bool = false
    @Published var showSignUpPassword: Bool = false
    @Published var showConfirmPassword: Bool = false

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var onAuthenticated: (() -> Void)?

    // MARK: - Validation

    var passwordsMatch: Bool {
        !signUpData.password.isEmpty &&
        signUpData.password == signUpData.confirmPassword
    }

    var isSignInValid: Bool {
        !signInData.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !signInData.password.isEmpty
    }

    var isSignUpValid: Bool {
        let emailOk = !signUpData.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let pwOk = signUpData.password.count >= 8
        return emailOk && pwOk && passwordsMatch
    }

    var passwordStrength: Int {
        let pw = signUpData.password
        var score = 0
        if pw.count >= 8 { score += 1 }
        if pw.range(of: #"[A-Z]"#, options: .regularExpression) != nil { score += 1 }
        if pw.range(of: #"[0-9]"#, options: .regularExpression) != nil { score += 1 }
        if pw.range(of: #"[^\w]"#, options: .regularExpression) != nil { score += 1 }
        return min(score, 4)
    }

    var strengthLabel: String {
        switch passwordStrength {
        case 0, 1: return "Weak"
        case 2:    return "Okay"
        case 3:    return "Strong"
        default:   return "Very strong"
        }
    }

    var strengthColor: Color {
        switch passwordStrength {
        case 0, 1: return .red
        case 2:    return .orange
        default:   return .green
        }
    }

    // MARK: - Actions

    func switchToSignUp() { withAnimation { showSignUp = true }; errorMessage = nil }
    func switchToSignIn() { withAnimation { showSignUp = false }; errorMessage = nil }
    func handleSignIn()   { Task { await signIn() } }
    func handleSignUp()   { Task { await signUp() } }

    // MARK: - Sign In

    private func signIn() async {
        guard isSignInValid else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let payload = LoginRequest(
            email: signInData.email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: signInData.password
        )

        do {
            let token: TokenResponse = try await APIClient.post(path: "/auth/login", body: payload)
            TokenStore.save(token.accessToken)
            onAuthenticated?()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Sign in failed. Please check your credentials."
        }
    }

    // MARK: - Sign Up

    private func signUp() async {
        guard isSignUpValid else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let payload = SignupRequest(
            email: signUpData.email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: signUpData.password
        )

        do {
            let token: TokenResponse = try await APIClient.post(path: "/auth/signup", body: payload)
            TokenStore.save(token.accessToken)
            onAuthenticated?()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Sign up failed. Please try again."
        }
    }
}
