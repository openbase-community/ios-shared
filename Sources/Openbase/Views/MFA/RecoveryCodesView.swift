import SwiftUI

/// View recovery codes
public struct RecoveryCodesView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var recoveryData: RecoveryCodesData?
    @State private var isLoading = true
    @State private var error: String?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Loading recovery codes...")
                        .padding(.top, 64)
                } else if let data = recoveryData {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("Recovery Codes")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("\(data.unusedCodeCount) of \(data.totalCodeCount) codes remaining")
                            .font(.subheadline)
                            .foregroundColor(data.unusedCodeCount <= 2 ? .orange : .secondary)
                    }
                    .padding(.top, 16)

                    // Info box
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Keep these codes safe")
                                .fontWeight(.semibold)
                        }

                        Text("Recovery codes can be used to access your account if you lose your authenticator device. Each code can only be used once.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Codes list
                    if let codes = data.unusedCodes, !codes.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(codes, id: \.self) { code in
                                HStack {
                                    Text(code)
                                        .font(.system(.body, design: .monospaced))
                                    Spacer()
                                    Button {
                                        UIPasteboard.general.string = code
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }

                        // Copy all button
                        Button {
                            UIPasteboard.general.string = codes.joined(separator: "\n")
                        } label: {
                            Label("Copy All Codes", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Text("No unused codes available. Generate new codes to get recovery codes.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else if let error = error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Try Again") {
                            Task { await loadCodes() }
                        }
                    }
                    .padding(.top, 64)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Recovery Codes")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCodes()
        }
    }

    private func loadCodes() async {
        isLoading = true
        error = nil

        do {
            let response = try await authManager.client.getRecoveryCodes()
            if let data = response.data {
                recoveryData = data
            } else {
                error = response.errors?.first?.message ?? "Failed to load recovery codes"
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        RecoveryCodesView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
