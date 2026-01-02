import SwiftUI

/// Request a login code to be sent to email
public struct RequestLoginCodeView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var isLoading = false
    @State private var errors: [APIFieldError]?

    /// Called when code is sent successfully, passes the email
    public var onCodeSent: ((String) -> Void)?

    /// Called when user wants to login with password instead
    public var onLoginWithPasswordTapped: (() -> Void)?

    public init(
        onCodeSent: ((String) -> Void)? = nil,
        onLoginWithPasswordTapped: (() -> Void)? = nil
    ) {
        self.onCodeSent = onCodeSent
        self.onLoginWithPasswordTapped = onLoginWithPasswordTapped
    }

    private var isFormValid: Bool {
        !email.isEmpty
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Sign In with Code")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("We'll send a sign-in code to your email")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

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

                // Request button
                LoadingButton("Send Code", isLoading: isLoading) {
                    await requestCode()
                }
                .disabled(!isFormValid)

                // Login with password link
                if let onLoginWithPasswordTapped = onLoginWithPasswordTapped {
                    Button("Sign in with password instead") {
                        onLoginWithPasswordTapped()
                    }
                    .font(.subheadline)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Login with Code")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func requestCode() async {
        isLoading = true
        errors = nil

        do {
            let response = try await authManager.requestLoginCode(email: email)

            if response.isSuccess || response.status == 401 {
                // 401 means code was sent and we need to confirm
                onCodeSent?(email)
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
        RequestLoginCodeView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
