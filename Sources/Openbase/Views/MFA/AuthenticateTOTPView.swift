import SwiftUI

/// Authenticate with TOTP code during login or reauthentication
public struct AuthenticateTOTPView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var code = ""
    @State private var isLoading = false
    @State private var errors: [APIFieldError]?

    /// Whether this is a reauthentication (vs login)
    public let isReauthentication: Bool

    /// Called when authentication succeeds
    public var onSuccess: (() -> Void)?

    /// Called when user wants to use recovery code instead
    public var onUseRecoveryCode: (() -> Void)?

    public init(
        isReauthentication: Bool = false,
        onSuccess: (() -> Void)? = nil,
        onUseRecoveryCode: (() -> Void)? = nil
    ) {
        self.isReauthentication = isReauthentication
        self.onSuccess = onSuccess
        self.onUseRecoveryCode = onUseRecoveryCode
    }

    private var isFormValid: Bool {
        code.count >= 6
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)

                    Text("Two-Factor Authentication")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Enter the code from your authenticator app")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                // Form
                VStack(spacing: 16) {
                    AuthTextField(
                        "Authenticator Code",
                        placeholder: "000000",
                        text: $code,
                        fieldType: .code,
                        errors: errors,
                        errorParam: "code"
                    )
                    .frame(maxWidth: 200)

                    // Global errors
                    FormErrorsView(errors: errors)
                }

                // Verify button
                LoadingButton("Verify", isLoading: isLoading) {
                    await authenticate()
                }
                .disabled(!isFormValid)

                // Recovery code link
                if let onUseRecoveryCode = onUseRecoveryCode {
                    Button("Use recovery code instead") {
                        onUseRecoveryCode()
                    }
                    .font(.subheadline)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Verify Identity")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func authenticate() async {
        isLoading = true
        errors = nil

        do {
            let response: AuthResponse<AuthData>
            if isReauthentication {
                response = try await authManager.mfaReauthenticate(code: code)
            } else {
                response = try await authManager.mfaAuthenticate(code: code)
            }

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
        AuthenticateTOTPView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
