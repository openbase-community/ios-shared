import SwiftUI

/// Deactivate TOTP authenticator
public struct DeactivateTOTPView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var isLoading = false
    @State private var error: String?

    /// Called when TOTP is deactivated successfully
    public var onSuccess: (() -> Void)?

    /// Called when user cancels
    public var onCancel: (() -> Void)?

    public init(
        onSuccess: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.onSuccess = onSuccess
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            // Header
            VStack(spacing: 8) {
                Text("Remove Authenticator")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Are you sure you want to remove your authenticator app? This will disable two-factor authentication for your account.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Warning box
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shield.slash")
                        .foregroundColor(.orange)
                    Text("Security Warning")
                        .fontWeight(.semibold)
                }

                Text("Your account will be less secure without two-factor authentication. We recommend keeping it enabled.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                LoadingButton("Remove Authenticator", isLoading: isLoading, style: .destructive) {
                    await deactivateTOTP()
                }

                if let onCancel = onCancel {
                    Button("Keep Authenticator") {
                        onCancel()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .padding()
        .navigationTitle("Remove 2FA")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deactivateTOTP() async {
        isLoading = true
        error = nil

        do {
            let response = try await authManager.client.deactivateTOTPAuthenticator()

            if response.isSuccess {
                onSuccess?()
            } else {
                error = response.errors?.first?.message ?? "Failed to remove authenticator"
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        DeactivateTOTPView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
