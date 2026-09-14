import SwiftUI

struct BannerHeader: View {
    let imageName: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 148)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Palette.background.opacity(0.4), radius: 12, x: 0, y: 6)

            Text(title)
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundColor(Palette.onBackdrop)
                .shadow(color: Palette.ink.opacity(0.45), radius: 6, x: 0, y: 2)
            Text(subtitle)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(Palette.onBackdrop.opacity(0.92))
                .shadow(color: Palette.ink.opacity(0.35), radius: 4, x: 0, y: 1)
        }
    }
}
