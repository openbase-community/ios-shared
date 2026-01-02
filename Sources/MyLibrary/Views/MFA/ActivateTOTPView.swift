import SwiftUI

/// Activate TOTP (Time-based One-Time Password) authenticator
public struct ActivateTOTPView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var totpSetup: TOTPSetup?
    @State private var code = ""
    @State private var isLoading = true
    @State private var isActivating = false
    @State private var errors: [APIFieldError]?

    /// Called when TOTP is activated successfully
    public var onSuccess: (() -> Void)?

    public init(onSuccess: (() -> Void)? = nil) {
        self.onSuccess = onSuccess
    }

    private var isFormValid: Bool {
        code.count >= 6
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Loading setup...")
                        .padding(.top, 64)
                } else if let setup = totpSetup {
                    // Header
                    VStack(spacing: 8) {
                        Text("Set Up Authenticator")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Scan the QR code with your authenticator app")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)

                    // QR Code placeholder
                    VStack(spacing: 12) {
                        if let totpUrl = setup.totpUrl {
                            // In a real app, you'd generate a QR code image here
                            // For now, show a placeholder with the URL
                            VStack {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 120))
                                    .foregroundColor(.primary)

                                Text("Scan this with your authenticator app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 200, height: 200)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                            // Show URL for manual entry (could be hidden behind a button)
                            Text(totpUrl)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .padding(.horizontal)
                        }
                    }

                    // Manual entry section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or enter this code manually:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Text(setup.secret)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)

                            Button {
                                UIPasteboard.general.string = setup.secret
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.vertical, 8)

                    // Verification form
                    VStack(spacing: 16) {
                        Text("Enter the code from your authenticator app to verify:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        AuthTextField(
                            "Verification Code",
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

                    // Activate button
                    LoadingButton("Activate", isLoading: isActivating) {
                        await activateTOTP()
                    }
                    .disabled(!isFormValid)
                } else {
                    // Error loading setup
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("Failed to load setup")
                            .font(.headline)

                        Button("Try Again") {
                            Task { await loadSetup() }
                        }
                    }
                    .padding(.top, 64)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Set Up 2FA")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadSetup()
        }
    }

    private func loadSetup() async {
        isLoading = true
        errors = nil

        do {
            let response = try await authManager.client.getTOTPAuthenticator()
            if let data = response.data {
                totpSetup = data
            } else {
                errors = response.errors
            }
        } catch {
            errors = [APIFieldError(param: nil, code: "error", message: error.localizedDescription)]
        }

        isLoading = false
    }

    private func activateTOTP() async {
        isActivating = true
        errors = nil

        do {
            let response = try await authManager.client.activateTOTPAuthenticator(code: code)

            if response.isSuccess {
                onSuccess?()
            } else {
                errors = response.errors
            }
        } catch {
            errors = [APIFieldError(param: nil, code: "error", message: error.localizedDescription)]
        }

        isActivating = false
    }
}

#Preview {
    NavigationStack {
        ActivateTOTPView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
