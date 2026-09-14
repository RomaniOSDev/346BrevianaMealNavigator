import SwiftUI

struct DinnerDiceSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let pool: [Recipe]

    @State private var pick: Recipe?
    @State private var favoritesOnly = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BannerHeader(
                        imageName: "BannerPasta",
                        title: "Dinner dice",
                        subtitle: "Let the cookbook pick tonight so nobody has to argue."
                    )

                    CookbookCard {
                        Toggle(isOn: $favoritesOnly) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Favorites only")
                                    .font(.system(.headline, design: .serif))
                                    .foregroundColor(Palette.ink)
                                Text("Roll from hearted cards when you already know the household hits.")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(Palette.muted)
                            }
                        }
                        .tint(Palette.primary)
                    }

                    if let pick {
                        NavigationLink(value: pick.id) {
                            RecipeOverviewCard(recipe: pick, isFavorite: store.isFavorite(pick.id))
                        }
                        .buttonStyle(.plain)
                    } else {
                        EmptyStateView(
                            symbol: "dice.fill",
                            title: "No plate on the table yet",
                            message: "Tap roll and a recipe from the current cookbook filter will land here."
                        )
                    }

                    GradientActionButton(title: pick == nil ? "Roll a plate" : "Roll again", systemImage: "dice.fill") {
                        roll()
                    }
                    .disabled(activePool.isEmpty)

                    if activePool.isEmpty {
                        Text("No recipes match this roll. Clear filters or heart a card first.")
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                            .foregroundColor(Palette.onBackdrop)
                    }
                }
                .padding(18)
            }
            .kitchenScreen()
            .navigationTitle("Dinner dice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Palette.onBackdrop)
                }
            }
            .navigationDestination(for: UUID.self) { recipeID in
                if let recipe = store.recipe(id: recipeID) {
                    RecipeDetailView(recipe: recipe)
                }
            }
            .onAppear {
                if pick == nil {
                    roll()
                }
            }
            .onChange(of: favoritesOnly) { _ in
                roll()
            }
        }
    }

    private var activePool: [Recipe] {
        if favoritesOnly {
            return pool.filter { recipe in store.isFavorite(recipe.id) }
        }
        return pool
    }

    private func roll() {
        let source = activePool
        guard source.isEmpty == false else {
            pick = nil
            return
        }
        if source.count == 1 {
            pick = source[0]
            return
        }
        pick = source.filter { recipe in recipe.id != pick?.id }.randomElement() ?? source.randomElement()
    }
}
