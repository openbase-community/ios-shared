import SwiftUI

/// Verify an email address using a key from email link
public struct VerifyEmailView: View {
    @Environment(AuthManager.self) private var authManager

    /// The email verification key from the email link
    public let key: String

    @State private var isLoading = true
    @State private var isVerifying = false
    @State private var email: String?
    @State private var user: User?
    @State private var isKeyValid = false
    @State private var isAlreadyVerified = false
    @State private var errors: [APIFieldError]?
    @State private var verificationComplete = false

    /// Called when verification succeeds
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

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading {
                    // Loading state
                    ProgressView("Validating link...")
                        .padding(.top, 64)
                } else if verificationComplete {
                    // Success state
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.green)

                        Text("Email Verified!")
                            .font(.title2)
                            .fontWeight(.bold)

                        if let email = email {
                            Text("\(email) has been verified successfully.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 64)
                } else if isAlreadyVerified {
                    // Already verified
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.green)

                        Text("Already Verified")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("This email address has already been verified.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
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

                        Text("This verification link is no longer valid. Please request a new verification email.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 64)
                } else {
                    // Confirmation view
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 64))
                            .foregroundColor(.accentColor)

                        Text("Verify Email")
                            .font(.title2)
                            .fontWeight(.bold)

                        if let email = email {
                            Text("Confirm verification for:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(email)
                                .font(.headline)
                        }

                        if let user = user {
                            Text("Account: \(user.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 64)

                    // Global errors
                    FormErrorsView(errors: errors)

                    // Verify button
                    LoadingButton("Verify Email", isLoading: isVerifying) {
                        await verifyEmail()
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Verify Email")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await checkVerification()
        }
    }

    private func checkVerification() async {
        isLoading = true

        do {
            let response = try await authManager.client.getEmailVerification(key: key)
            if response.isSuccess, let data = response.data {
                isKeyValid = true
                email = data.email
                user = data.user
            } else {
                isKeyValid = false
                onInvalidKey?()
            }
        } catch {
            isKeyValid = false
            onInvalidKey?()
        }

        isLoading = false
    }

    private func verifyEmail() async {
        isVerifying = true
        errors = nil

        do {
            let response = try await authManager.client.verifyEmail(key: key)

            if response.isSuccess {
                verificationComplete = true
                authManager.updateState(from: response)
                onSuccess?()
            } else {
                errors = response.errors
            }
        } catch {
            errors = [APIFieldError(param: nil, code: "error", message: error.localizedDescription)]
        }

        isVerifying = false
    }
}

#Preview {
    NavigationStack {
        VerifyEmailView(key: "test-key")
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
