import SwiftUI

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        CookbookCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Palette.primary)
                Text(title)
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundColor(Palette.ink)
                Text(message)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                if let actionTitle, let action {
                    GradientActionButton(title: actionTitle, systemImage: "arrow.right") {
                        action()
                    }
                }
            }
        }
    }
}
