import SwiftUI

/// Confirm login with the code sent to email
public struct ConfirmLoginCodeView: View {
    @Environment(AuthManager.self) private var authManager

    /// The email the code was sent to
    public let email: String

    @State private var code = ""
    @State private var isLoading = false
    @State private var errors: [APIFieldError]?

    /// Called when login succeeds
    public var onSuccess: (() -> Void)?

    /// Called when user wants to request a new code
    public var onResendCode: (() -> Void)?

    public init(
        email: String,
        onSuccess: (() -> Void)? = nil,
        onResendCode: (() -> Void)? = nil
    ) {
        self.email = email
        self.onSuccess = onSuccess
        self.onResendCode = onResendCode
    }

    private var isFormValid: Bool {
        !code.isEmpty
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Enter Code")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("We sent a code to")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(email)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.top, 32)

                // Form
                VStack(spacing: 16) {
                    AuthTextField(
                        "Code",
                        placeholder: "Enter the code",
                        text: $code,
                        fieldType: .code,
                        errors: errors,
                        errorParam: "code"
                    )

                    // Global errors
                    FormErrorsView(errors: errors)
                }

                // Confirm button
                LoadingButton("Verify Code", isLoading: isLoading) {
                    await confirmCode()
                }
                .disabled(!isFormValid)

                // Resend code link
                if let onResendCode = onResendCode {
                    Button("Didn't receive the code? Send again") {
                        onResendCode()
                    }
                    .font(.subheadline)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Verify Code")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func confirmCode() async {
        isLoading = true
        errors = nil

        do {
            let response = try await authManager.confirmLoginCode(code: code)

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
        ConfirmLoginCodeView(email: "user@example.com")
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
