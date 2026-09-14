import SwiftUI

struct LeftoversView: View {
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BannerHeader(
                    imageName: "BannerGroceries",
                    title: "Leftovers",
                    subtitle: "What is still in the fridge, and which plate it should become tomorrow."
                )

                if store.leftovers.isEmpty {
                    EmptyStateView(
                        symbol: "refrigerator.fill",
                        title: "No leftovers logged",
                        message: "After a family plate, save leftovers from the recipe card."
                    )
                } else {
                    ForEach(store.leftovers) { item in
                        CookbookCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(item.name)
                                    .font(.system(.title3, design: .serif).weight(.bold))
                                    .foregroundColor(Palette.ink)
                                Text("From \(item.fromRecipeTitle)")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(Palette.muted)
                                if item.suggestedRecipeTitle.isEmpty == false {
                                    Text("Next idea: \(item.suggestedRecipeTitle)")
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundColor(Palette.primary)
                                    if let recipeId = item.suggestedRecipeId {
                                        NavigationLink(value: recipeId) {
                                            Text("Open that plate")
                                                .font(.system(.caption, design: .rounded).weight(.bold))
                                                .foregroundColor(Palette.primary)
                                        }
                                    }
                                }
                                SoftActionButton(title: "Used it up", systemImage: "trash") {
                                    store.deleteLeftover(item.id)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .kitchenScreen()
        .navigationTitle("Leftovers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationDestination(for: UUID.self) { recipeID in
            if let recipe = store.recipe(id: recipeID) {
                RecipeDetailView(recipe: recipe)
            }
        }
    }
}
