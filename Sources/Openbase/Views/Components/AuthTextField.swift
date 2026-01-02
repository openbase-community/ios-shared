import SwiftUI

/// A styled text field for authentication forms
public struct AuthTextField: View {
    /// Field label
    public let label: String

    /// Placeholder text
    public let placeholder: String

    /// Binding to the text value
    @Binding public var text: String

    /// Field type for keyboard and content type
    public let fieldType: AuthTextFieldType

    /// Optional errors to display
    public let errors: [APIFieldError]?

    /// The field param name for error filtering
    public let errorParam: String?

    /// Whether the field is disabled
    public let isDisabled: Bool

    public init(
        _ label: String,
        placeholder: String = "",
        text: Binding<String>,
        fieldType: AuthTextFieldType = .text,
        errors: [APIFieldError]? = nil,
        errorParam: String? = nil,
        isDisabled: Bool = false
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.fieldType = fieldType
        self.errors = errors
        self.errorParam = errorParam
        self.isDisabled = isDisabled
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Group {
                if fieldType.isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.roundedBorder)
            .textContentType(fieldType.contentType)
            .keyboardType(fieldType.keyboardType)
            .textInputAutocapitalization(fieldType.autocapitalization)
            .autocorrectionDisabled(fieldType.disableAutocorrection)
            .disabled(isDisabled)

            if let errorParam = errorParam {
                FormErrorsView(errors: errors, param: errorParam)
            }
        }
    }
}

/// Types of authentication text fields
public enum AuthTextFieldType {
    case text
    case email
    case password
    case newPassword
    case code
    case username

    var isSecure: Bool {
        switch self {
        case .password, .newPassword:
            return true
        default:
            return false
        }
    }

    var contentType: UITextContentType? {
        switch self {
        case .text:
            return nil
        case .email:
            return .emailAddress
        case .password:
            return .password
        case .newPassword:
            return .newPassword
        case .code:
            return .oneTimeCode
        case .username:
            return .username
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .email:
            return .emailAddress
        case .code:
            return .numberPad
        default:
            return .default
        }
    }

    var autocapitalization: TextInputAutocapitalization {
        switch self {
        case .email, .password, .newPassword, .code, .username:
            return .never
        case .text:
            return .sentences
        }
    }

    var disableAutocorrection: Bool {
        switch self {
        case .email, .password, .newPassword, .code, .username:
            return true
        case .text:
            return false
        }
    }
}

/// A secure password field with visibility toggle
public struct SecureInputField: View {
    /// Field label
    public let label: String

    /// Placeholder text
    public let placeholder: String

    /// Binding to the text value
    @Binding public var text: String

    /// Content type for password autofill
    public let contentType: UITextContentType

    /// Optional errors to display
    public let errors: [APIFieldError]?

    /// The field param name for error filtering
    public let errorParam: String?

    @State private var isSecure = true

    public init(
        _ label: String,
        placeholder: String = "",
        text: Binding<String>,
        contentType: UITextContentType = .password,
        errors: [APIFieldError]? = nil,
        errorParam: String? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.contentType = contentType
        self.errors = errors
        self.errorParam = errorParam
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            HStack {
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .textContentType(contentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button {
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )

            if let errorParam = errorParam {
                FormErrorsView(errors: errors, param: errorParam)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AuthTextField(
            "Email",
            placeholder: "Enter your email",
            text: .constant(""),
            fieldType: .email,
            errors: [APIFieldError(param: "email", code: "invalid", message: "Invalid email address")],
            errorParam: "email"
        )

        AuthTextField(
            "Password",
            placeholder: "Enter your password",
            text: .constant(""),
            fieldType: .password
        )

        SecureInputField(
            "Password",
            placeholder: "Enter password",
            text: .constant("secret123")
        )

        AuthTextField(
            "Verification Code",
            placeholder: "000000",
            text: .constant(""),
            fieldType: .code
        )
    }
    .padding()
}
