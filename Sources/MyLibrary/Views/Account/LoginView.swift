import SwiftUI

/// Login view with email and password
public struct LoginView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errors: [APIFieldError]?

    /// Called when login succeeds
    public var onSuccess: (() -> Void)?

    /// Called when user wants to sign up instead
    public var onSignUpTapped: (() -> Void)?

    /// Called when user wants to reset password
    public var onForgotPasswordTapped: (() -> Void)?

    /// Called when user wants to use login code instead
    public var onLoginByCodeTapped: (() -> Void)?

    public init(
        onSuccess: (() -> Void)? = nil,
        onSignUpTapped: (() -> Void)? = nil,
        onForgotPasswordTapped: (() -> Void)? = nil,
        onLoginByCodeTapped: (() -> Void)? = nil
    ) {
        self.onSuccess = onSuccess
        self.onSignUpTapped = onSignUpTapped
        self.onForgotPasswordTapped = onForgotPasswordTapped
        self.onLoginByCodeTapped = onLoginByCodeTapped
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Sign in to your account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)

                // Form
                VStack(spacing: 16) {
                    AuthTextField(
                        "Email",
                        placeholder: "Enter your email",
                        text: $email,
                        fieldType: .email,
                        errors: errors,
                        errorParam: "email"
                    )

                    AuthTextField(
                        "Password",
                        placeholder: "Enter your password",
                        text: $password,
                        fieldType: .password,
                        errors: errors,
                        errorParam: "password"
                    )

                    // Global errors
                    FormErrorsView(errors: errors)
                }

                // Login button
                LoadingButton("Sign In", isLoading: isLoading) {
                    await login()
                }
                .disabled(!isFormValid)

                // Links
                VStack(spacing: 12) {
                    if let onForgotPasswordTapped = onForgotPasswordTapped {
                        Button("Forgot password?") {
                            onForgotPasswordTapped()
                        }
                        .font(.subheadline)
                    }

                    if let onLoginByCodeTapped = onLoginByCodeTapped,
                       authManager.config?.account?.loginByCodeEnabled == true {
                        Button("Sign in with code") {
                            onLoginByCodeTapped()
                        }
                        .font(.subheadline)
                    }
                }

                Spacer()

                // Sign up link
                if let onSignUpTapped = onSignUpTapped {
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        Button("Sign Up") {
                            onSignUpTapped()
                        }
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
            }
            .padding()
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func login() async {
        isLoading = true
        errors = nil

        do {
            let response = try await authManager.login(email: email, password: password)

            if response.isSuccess {
                onSuccess?()
            } else {
                errors = response.errors
            }
        } catch {
            errors = [APIFieldError(param: nil, code: "error", message: error.localizedDescription)]
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
