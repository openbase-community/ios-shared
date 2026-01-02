import SwiftUI

/// A button that shows a loading indicator during async actions
public struct LoadingButton: View {
    /// Button title
    public let title: String

    /// Whether the button is in loading state
    public let isLoading: Bool

    /// The action to perform (async)
    public let action: () async -> Void

    /// Button style
    public var style: LoadingButtonStyle

    public init(
        _ title: String,
        isLoading: Bool,
        style: LoadingButtonStyle = .primary,
        action: @escaping () async -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(style.foregroundColor)
                }
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(8)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
    }
}

/// Button style options
public enum LoadingButtonStyle {
    case primary
    case secondary
    case destructive

    var backgroundColor: Color {
        switch self {
        case .primary:
            return .accentColor
        case .secondary:
            return Color(.systemGray5)
        case .destructive:
            return .red
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary:
            return .white
        case .secondary:
            return .primary
        case .destructive:
            return .white
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        LoadingButton("Sign In", isLoading: false) {
            try? await Task.sleep(for: .seconds(2))
        }

        LoadingButton("Loading...", isLoading: true) {}

        LoadingButton("Secondary", isLoading: false, style: .secondary) {}

        LoadingButton("Delete", isLoading: false, style: .destructive) {}
    }
    .padding()
}
