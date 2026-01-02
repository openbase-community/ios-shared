import SwiftUI

/// Generate new recovery codes
public struct GenerateRecoveryCodesView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var recoveryData: RecoveryCodesData?
    @State private var isGenerating = false
    @State private var hasGenerated = false
    @State private var error: String?

    /// Called when codes are generated successfully
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
        ScrollView {
            VStack(spacing: 24) {
                if hasGenerated, let data = recoveryData, let codes = data.unusedCodes {
                    // Success view with codes
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)

                        Text("Recovery Codes Generated")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Save these codes in a safe place. You won't be able to see them again.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)

                    // Warning box
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Important")
                                .fontWeight(.semibold)
                        }

                        Text("Your old recovery codes have been invalidated. Make sure to save these new codes.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)

                    // Codes list
                    VStack(spacing: 8) {
                        ForEach(codes, id: \.self) { code in
                            HStack {
                                Text(code)
                                    .font(.system(.body, design: .monospaced))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }

                    // Copy button
                    Button {
                        UIPasteboard.general.string = codes.joined(separator: "\n")
                    } label: {
                        Label("Copy All Codes", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)

                    // Done button
                    Button("Done") {
                        onSuccess?()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    // Confirmation view
                    VStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("Generate Recovery Codes")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Recovery codes can be used to access your account if you lose your authenticator device.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)

                    // Warning box
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Warning")
                                .fontWeight(.semibold)
                        }

                        Text("If you already have recovery codes, generating new ones will invalidate all existing codes.")
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
                        LoadingButton("Generate Codes", isLoading: isGenerating) {
                            await generateCodes()
                        }

                        if let onCancel = onCancel {
                            Button("Cancel") {
                                onCancel()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Recovery Codes")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func generateCodes() async {
        isGenerating = true
        error = nil

        do {
            let response = try await authManager.client.generateRecoveryCodes()

            if let data = response.data {
                recoveryData = data
                hasGenerated = true
            } else {
                error = response.errors?.first?.message ?? "Failed to generate codes"
            }
        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
    }
}

#Preview {
    NavigationStack {
        GenerateRecoveryCodesView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
