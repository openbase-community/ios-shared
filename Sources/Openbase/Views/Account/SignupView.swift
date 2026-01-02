import SwiftUI

/// Sign up view for new user registration
public struct SignupView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errors: [APIFieldError]?
    @State private var localErrors: [APIFieldError]?

    /// Called when signup succeeds
    public var onSuccess: (() -> Void)?

    /// Called when user wants to login instead
    public var onLoginTapped: (() -> Void)?

    public init(
        onSuccess: (() -> Void)? = nil,
        onLoginTapped: (() -> Void)? = nil
    ) {
        self.onSuccess = onSuccess
        self.onLoginTapped = onLoginTapped
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
    }

    private var allErrors: [APIFieldError] {
        (errors ?? []) + (localErrors ?? [])
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Sign up to get started")
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
                        errors: allErrors,
                        errorParam: "email"
                    )

                    AuthTextField(
                        "Password",
                        placeholder: "Create a password",
                        text: $password,
                        fieldType: .newPassword,
                        errors: allErrors,
                        errorParam: "password"
                    )

                    AuthTextField(
                        "Confirm Password",
                        placeholder: "Confirm your password",
                        text: $confirmPassword,
                        fieldType: .newPassword,
                        errors: allErrors,
                        errorParam: "password2"
                    )

                    // Global errors
                    FormErrorsView(errors: allErrors)
                }

                // Sign up button
                LoadingButton("Create Account", isLoading: isLoading) {
                    await signUp()
                }
                .disabled(!isFormValid)

                Spacer()

                // Login link
                if let onLoginTapped = onLoginTapped {
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)
                        Button("Sign In") {
                            onLoginTapped()
                        }
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
            }
            .padding()
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func signUp() async {
        localErrors = nil
        errors = nil

        // Validate passwords match
        if password != confirmPassword {
            localErrors = [APIFieldError(
                param: "password2",
                code: "mismatch",
                message: "Passwords do not match"
            )]
            return
        }

        isLoading = true

        do {
            let response = try await authManager.signUp(email: email, password: password)

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
        SignupView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
