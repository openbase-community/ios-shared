import SwiftUI

/// Complete OAuth signup when additional information is needed
public struct ProviderSignupView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var isLoading = false
    @State private var errors: [APIFieldError]?

    /// Called when signup completes successfully
    public var onSuccess: (() -> Void)?

    public init(onSuccess: (() -> Void)? = nil) {
        self.onSuccess = onSuccess
    }

    private var isFormValid: Bool {
        !email.isEmpty
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)

                    Text("Complete Sign Up")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Please provide your email address to complete your account setup")
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

                // Submit button
                LoadingButton("Complete Sign Up", isLoading: isLoading) {
                    await completeSignup()
                }
                .disabled(!isFormValid)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Complete Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func completeSignup() async {
        isLoading = true
        errors = nil

        do {
            let response = try await authManager.client.providerSignup(email: email)

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
        ProviderSignupView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
