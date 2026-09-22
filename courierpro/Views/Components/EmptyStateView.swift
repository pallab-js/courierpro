import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.6))
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel(actionTitle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorAlert: ViewModifier {
    @Binding var isPresented: Bool
    let message: String?

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $isPresented) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(message ?? "An unknown error occurred")
            }
    }
}

extension View {
    func errorAlert(isPresented: Binding<Bool>, message: String?) -> some View {
        modifier(ErrorAlert(isPresented: isPresented, message: message))
    }
}

struct CardModifier: ViewModifier {
    var cornerRadius: CGFloat = 10
    var shadowOpacity: Double = 0.06
    var shadowRadius: CGFloat = 4
    var shadowY: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, y: shadowY)
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 10, shadowOpacity: Double = 0.06, shadowRadius: CGFloat = 4, shadowY: CGFloat = 1) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius, shadowOpacity: shadowOpacity, shadowRadius: shadowRadius, shadowY: shadowY))
    }
}
