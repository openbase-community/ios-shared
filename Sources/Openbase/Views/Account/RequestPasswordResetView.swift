import SwiftUI

/// Request a password reset email
public struct RequestPasswordResetView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var isLoading = false
    @State private var errors: [APIFieldError]?
    @State private var showSuccess = false

    /// Called when reset email is sent
    public var onSuccess: (() -> Void)?

    /// Called when user wants to go back to login
    public var onBackToLogin: (() -> Void)?

    public init(
        onSuccess: (() -> Void)? = nil,
        onBackToLogin: (() -> Void)? = nil
    ) {
        self.onSuccess = onSuccess
        self.onBackToLogin = onBackToLogin
    }

    private var isFormValid: Bool {
        !email.isEmpty
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Reset Password")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Enter your email and we'll send you a link to reset your password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                if showSuccess {
                    // Success message
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.green)

                        Text("Check Your Email")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("We've sent a password reset link to \(email)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 32)
                } else {
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

                        // Global errors
                        FormErrorsView(errors: errors)
                    }

                    // Submit button
                    LoadingButton("Send Reset Link", isLoading: isLoading) {
                        await requestReset()
                    }
                    .disabled(!isFormValid)
                }

                // Back to login link
                if let onBackToLogin = onBackToLogin {
                    Button("Back to Login") {
                        onBackToLogin()
                    }
                    .font(.subheadline)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func requestReset() async {
        isLoading = true
        errors = nil

        do {
            let response = try await authManager.client.requestPasswordReset(email: email)

            if response.isSuccess {
                showSuccess = true
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
        RequestPasswordResetView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
