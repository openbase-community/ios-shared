import SwiftUI

/// Reset password using a key from email link
public struct ResetPasswordView: View {
    @Environment(AuthManager.self) private var authManager

    /// The password reset key from the email link
    public let key: String

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var isValidating = true
    @State private var errors: [APIFieldError]?
    @State private var localErrors: [APIFieldError]?
    @State private var user: User?
    @State private var isKeyValid = false

    /// Called when password is reset successfully
    public var onSuccess: (() -> Void)?

    /// Called when the key is invalid
    public var onInvalidKey: (() -> Void)?

    public init(
        key: String,
        onSuccess: (() -> Void)? = nil,
        onInvalidKey: (() -> Void)? = nil
    ) {
        self.key = key
        self.onSuccess = onSuccess
        self.onInvalidKey = onInvalidKey
    }

    private var isFormValid: Bool {
        !password.isEmpty && !confirmPassword.isEmpty
    }

    private var allErrors: [APIFieldError] {
        (errors ?? []) + (localErrors ?? [])
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isValidating {
                    // Loading state
                    ProgressView("Validating link...")
                        .padding(.top, 64)
                } else if !isKeyValid {
                    // Invalid key
                    VStack(spacing: 16) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.red)

                        Text("Invalid or Expired Link")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("This password reset link is no longer valid. Please request a new one.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 64)
                } else {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create New Password")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        if let user = user {
                            Text("for \(user.email)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 32)

                    // Form
                    VStack(spacing: 16) {
                        SecureInputField(
                            "New Password",
                            placeholder: "Enter new password",
                            text: $password,
                            contentType: .newPassword,
                            errors: allErrors,
                            errorParam: "password"
                        )

                        SecureInputField(
                            "Confirm Password",
                            placeholder: "Confirm new password",
                            text: $confirmPassword,
                            contentType: .newPassword,
                            errors: allErrors,
                            errorParam: "password2"
                        )

                        // Global errors
                        FormErrorsView(errors: allErrors)
                    }

                    // Submit button
                    LoadingButton("Reset Password", isLoading: isLoading) {
                        await resetPassword()
                    }
                    .disabled(!isFormValid)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await validateKey()
        }
    }

    private func validateKey() async {
        isValidating = true

        do {
            let response = try await authManager.client.getPasswordReset(key: key)
            if response.isSuccess {
                isKeyValid = true
                user = response.data?.user
            } else {
                isKeyValid = false
                onInvalidKey?()
            }
        } catch {
            isKeyValid = false
            onInvalidKey?()
        }

        isValidating = false
    }

    private func resetPassword() async {
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
            let response = try await authManager.client.resetPassword(key: key, password: password)

            if response.isSuccess {
                authManager.updateState(from: response)
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
        ResetPasswordView(key: "test-key")
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
