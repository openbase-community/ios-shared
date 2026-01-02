import SwiftUI

/// Logout confirmation view
public struct LogoutView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var isLoading = false
    @State private var error: String?

    /// Called after successful logout
    public var onLogout: (() -> Void)?

    /// Called when user cancels
    public var onCancel: (() -> Void)?

    public init(
        onLogout: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.onLogout = onLogout
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            // Header
            VStack(spacing: 8) {
                Text("Sign Out")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Are you sure you want to sign out?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                LoadingButton("Sign Out", isLoading: isLoading, style: .destructive) {
                    await logout()
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
        .padding()
        .navigationTitle("Sign Out")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func logout() async {
        isLoading = true
        error = nil

        do {
            try await authManager.logout()
            onLogout?()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        LogoutView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
