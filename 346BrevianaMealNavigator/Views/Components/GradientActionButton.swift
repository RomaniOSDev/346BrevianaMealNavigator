import SwiftUI

struct GradientActionButton: View {
    let title: String
    let systemImage: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(.headline, design: .serif))
            }
            .foregroundColor(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Palette.primary, Palette.accent, Palette.background],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Palette.primary.opacity(0.42), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(isEnabled == false)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

struct SoftActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundColor(Palette.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Palette.card)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Palette.primary.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
