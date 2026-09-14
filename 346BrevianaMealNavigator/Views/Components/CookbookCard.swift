import SwiftUI

struct CookbookCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .padding(.leading, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Palette.primary, Palette.accent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 7)
                    .padding(.vertical, 16)
                    .padding(.leading, 8)
            }
            .shadow(color: Palette.ink.opacity(0.16), radius: 14, x: 0, y: 8)
    }
}

struct PaceChip: View {
    let pace: MealPace

    var body: some View {
        Label(pace.label, systemImage: pace.symbol)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(Palette.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Palette.primary.opacity(0.14))
            .clipShape(Capsule())
    }
}

struct DietChip: View {
    let tag: DietTag

    var body: some View {
        Text(tag.label)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(Palette.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Palette.accent.opacity(0.18))
            .clipShape(Capsule())
    }
}

struct RecipeOverviewCard: View {
    let recipe: Recipe
    let isFavorite: Bool

    var body: some View {
        CookbookCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(recipe.title)
                        .font(.system(.title3, design: .serif).weight(.bold))
                        .foregroundColor(Palette.ink)
                    Spacer(minLength: 8)
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(Palette.primary)
                }
                Text(recipe.summary)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    PaceChip(pace: recipe.pace)
                    Text(recipe.slot.label)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Palette.muted)
                    Text(KitchenFormat.minutesLabel(recipe.minutes))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Palette.muted)
                    Text("\(recipe.servings) servings")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Palette.muted)
                }
            }
        }
    }
}
