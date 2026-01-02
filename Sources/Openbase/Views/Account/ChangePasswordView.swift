import SwiftUI

/// Change or set password for the account
public struct ChangePasswordView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errors: [APIFieldError]?
    @State private var localErrors: [APIFieldError]?
    @State private var showSuccess = false

    /// Whether the user currently has a password set
    public let hasPassword: Bool

    /// Called when password is changed successfully
    public var onSuccess: (() -> Void)?

    public init(hasPassword: Bool = true, onSuccess: (() -> Void)? = nil) {
        self.hasPassword = hasPassword
        self.onSuccess = onSuccess
    }

    private var isFormValid: Bool {
        if hasPassword {
            return !currentPassword.isEmpty && !newPassword.isEmpty && !confirmPassword.isEmpty
        } else {
            return !newPassword.isEmpty && !confirmPassword.isEmpty
        }
    }

    private var allErrors: [APIFieldError] {
        (errors ?? []) + (localErrors ?? [])
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(hasPassword ? "Change Password" : "Set Password")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(hasPassword ? "Enter your current password and choose a new one" : "Create a password for your account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                // Form
                VStack(spacing: 16) {
                    if hasPassword {
                        SecureInputField(
                            "Current Password",
                            placeholder: "Enter current password",
                            text: $currentPassword,
                            contentType: .password,
                            errors: allErrors,
                            errorParam: "current_password"
                        )
                    }

                    SecureInputField(
                        "New Password",
                        placeholder: "Enter new password",
                        text: $newPassword,
                        contentType: .newPassword,
                        errors: allErrors,
                        errorParam: "new_password"
                    )

                    SecureInputField(
                        "Confirm New Password",
                        placeholder: "Confirm new password",
                        text: $confirmPassword,
                        contentType: .newPassword,
                        errors: allErrors,
                        errorParam: "new_password2"
                    )

                    // Global errors
                    FormErrorsView(errors: allErrors)
                }

                // Submit button
                LoadingButton(hasPassword ? "Change Password" : "Set Password", isLoading: isLoading) {
                    await changePassword()
                }
                .disabled(!isFormValid)

                if showSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Password updated successfully")
                            .foregroundColor(.green)
                    }
                    .font(.subheadline)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle(hasPassword ? "Change Password" : "Set Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func changePassword() async {
        localErrors = nil
        errors = nil
        showSuccess = false

        // Validate passwords match
        if newPassword != confirmPassword {
            localErrors = [APIFieldError(
                param: "new_password2",
                code: "mismatch",
                message: "Passwords do not match"
            )]
            return
        }

        isLoading = true

        do {
            let response = try await authManager.client.changePassword(
                currentPassword: hasPassword ? currentPassword : nil,
                newPassword: newPassword
            )

            if response.isSuccess {
                showSuccess = true
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
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
        ChangePasswordView(hasPassword: true)
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
