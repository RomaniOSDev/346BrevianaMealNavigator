import SwiftUI

struct FeedbackBanner: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(Palette.primary)
            Text(text)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Palette.background.opacity(0.35), radius: 10, x: 0, y: 6)
    }
}
