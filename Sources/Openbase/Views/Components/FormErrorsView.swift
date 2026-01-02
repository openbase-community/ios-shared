import SwiftUI

/// Displays form validation errors
/// Filters errors by field parameter and displays them in red
public struct FormErrorsView: View {
    /// All errors from the API response
    public let errors: [APIFieldError]?

    /// Optional field name to filter errors (nil shows global errors only)
    public let param: String?

    public init(errors: [APIFieldError]?, param: String? = nil) {
        self.errors = errors
        self.param = param
    }

    /// Filtered errors based on param
    private var filteredErrors: [APIFieldError] {
        guard let errors = errors else { return [] }

        if let param = param {
            // Show errors for specific field
            return errors.filter { $0.param == param }
        } else {
            // Show global errors (no param)
            return errors.filter { $0.param == nil }
        }
    }

    public var body: some View {
        if !filteredErrors.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(filteredErrors) { error in
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                        Text(error.message)
                            .font(.caption)
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        FormErrorsView(errors: [
            APIFieldError(param: nil, code: "invalid", message: "Invalid credentials"),
            APIFieldError(param: "email", code: "required", message: "Email is required"),
            APIFieldError(param: "password", code: "too_short", message: "Password must be at least 8 characters")
        ])

        Divider()

        Text("Email field errors:")
        FormErrorsView(errors: [
            APIFieldError(param: "email", code: "required", message: "Email is required")
        ], param: "email")
    }
    .padding()
}
