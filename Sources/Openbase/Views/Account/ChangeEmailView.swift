import SwiftUI

/// Manage email addresses for the account
public struct ChangeEmailView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var emailAddresses: [EmailAddress] = []
    @State private var newEmail = ""
    @State private var isLoading = false
    @State private var isAddingEmail = false
    @State private var errors: [APIFieldError]?

    public init() {}

    public var body: some View {
        List {
            // Current emails section
            Section {
                ForEach(emailAddresses) { email in
                    EmailRow(
                        email: email,
                        onVerify: { await requestVerification(email.email) },
                        onMakePrimary: { await makePrimary(email.email) },
                        onDelete: { await deleteEmail(email.email) }
                    )
                }
            } header: {
                Text("Email Addresses")
            } footer: {
                Text("Your primary email address is used for account notifications.")
            }

            // Add new email section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    AuthTextField(
                        "New Email",
                        placeholder: "Enter new email",
                        text: $newEmail,
                        fieldType: .email,
                        errors: errors,
                        errorParam: "email"
                    )

                    LoadingButton("Add Email", isLoading: isAddingEmail) {
                        await addEmail()
                    }
                    .disabled(newEmail.isEmpty)
                }
            } header: {
                Text("Add Email")
            }

            // Global errors
            if let errors = errors, !errors.filter({ $0.param == nil }).isEmpty {
                Section {
                    FormErrorsView(errors: errors)
                }
            }
        }
        .navigationTitle("Manage Emails")
        .refreshable {
            await loadEmails()
        }
        .task {
            await loadEmails()
        }
        .overlay {
            if isLoading && emailAddresses.isEmpty {
                ProgressView()
            }
        }
    }

    private func loadEmails() async {
        isLoading = true
        do {
            let response = try await authManager.client.getEmailAddresses()
            if let data = response.data {
                emailAddresses = data
            }
        } catch {
            // Handle error silently or show alert
        }
        isLoading = false
    }

    private func addEmail() async {
        isAddingEmail = true
        errors = nil

        do {
            let response = try await authManager.client.addEmail(newEmail)
            if response.isSuccess, let data = response.data {
                emailAddresses = data
                newEmail = ""
            } else {
                errors = response.errors
            }
        } catch {
            errors = [APIFieldError(param: nil, code: "error", message: error.localizedDescription)]
        }

        isAddingEmail = false
    }

    private func requestVerification(_ email: String) async {
        do {
            _ = try await authManager.client.requestEmailVerification(email)
        } catch {
            // Handle error
        }
    }

    private func makePrimary(_ email: String) async {
        do {
            let response = try await authManager.client.markEmailAsPrimary(email)
            if let data = response.data {
                emailAddresses = data
            }
        } catch {
            // Handle error
        }
    }

    private func deleteEmail(_ email: String) async {
        do {
            let response = try await authManager.client.deleteEmail(email)
            if let data = response.data {
                emailAddresses = data
            }
        } catch {
            // Handle error
        }
    }
}

/// Row displaying an email address with actions
struct EmailRow: View {
    let email: EmailAddress
    let onVerify: () async -> Void
    let onMakePrimary: () async -> Void
    let onDelete: () async -> Void

    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(email.email)
                    .font(.body)

                Spacer()

                if email.primary {
                    Text("Primary")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(.accentColor)
                        .cornerRadius(4)
                }

                if email.verified {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }

            HStack(spacing: 16) {
                if !email.verified {
                    Button("Verify") {
                        Task {
                            isLoading = true
                            await onVerify()
                            isLoading = false
                        }
                    }
                    .font(.caption)
                    .disabled(isLoading)
                }

                if !email.primary && email.verified {
                    Button("Make Primary") {
                        Task {
                            isLoading = true
                            await onMakePrimary()
                            isLoading = false
                        }
                    }
                    .font(.caption)
                    .disabled(isLoading)
                }

                if !email.primary {
                    Button("Remove", role: .destructive) {
                        Task {
                            isLoading = true
                            await onDelete()
                            isLoading = false
                        }
                    }
                    .font(.caption)
                    .disabled(isLoading)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ChangeEmailView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
