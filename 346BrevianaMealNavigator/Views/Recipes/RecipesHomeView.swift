import SwiftUI

struct RecipesHomeView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var selectedTags: Set<DietTag> = []
    @State private var selectedPaces: Set<MealPace> = []
    @State private var selectedSlots: Set<MealSlot> = []
    @State private var showFilters = false
    @State private var showDice = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BannerHeader(
                        imageName: "BannerPasta",
                        title: "Weeknight Cookbook",
                        subtitle: "Pick a plate, fill the market, then start the timers."
                    )

                    searchField
                    controlRow
                    spotlightCard
                    cookAgainCard

                    if visibleRecipes.isEmpty {
                        EmptyStateView(
                            symbol: "book.closed",
                            title: "No matching plates",
                            message: "Try a shorter search or clear the dietary filters."
                        )
                    } else {
                        ForEach(visibleRecipes) { recipe in
                            NavigationLink(value: recipe.id) {
                                RecipeOverviewCard(
                                    recipe: recipe,
                                    isFavorite: store.isFavorite(recipe.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .kitchenScreen()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { recipeID in
                if let recipe = store.recipe(id: recipeID) {
                    RecipeDetailView(recipe: recipe)
                } else {
                    EmptyStateView(
                        symbol: "questionmark.folder",
                        title: "Recipe unavailable",
                        message: "That card is no longer in the cookbook."
                    )
                    .kitchenScreen()
                }
            }
            .sheet(isPresented: $showFilters) {
                RecipeFilterSheet(
                    selectedTags: $selectedTags,
                    selectedPaces: $selectedPaces,
                    selectedSlots: $selectedSlots
                )
                .environmentObject(store)
            }
            .sheet(isPresented: $showDice) {
                DinnerDiceSheet(pool: visibleRecipes.isEmpty ? store.catalog : visibleRecipes)
                    .environmentObject(store)
            }
            .onAppear {
                if selectedTags.isEmpty && store.userDietaryPreferences.isEmpty == false {
                    selectedTags = Set(store.userDietaryPreferences)
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Palette.primary)
            TextField("", text: $searchText, prompt: Text("Search titles or ingredients").foregroundColor(Palette.placeholder))
                .foregroundColor(Palette.ink)
                .tint(Palette.primary)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            if searchText.isEmpty == false {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Palette.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Palette.primary.opacity(0.28), lineWidth: 1)
        )
    }

    private var controlRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                SoftActionButton(title: "Filters", systemImage: "line.3.horizontal.decrease.circle") {
                    showFilters = true
                }
                SoftActionButton(
                    title: showFavoritesOnly ? "All cards" : "Favorites",
                    systemImage: showFavoritesOnly ? "heart.fill" : "heart"
                ) {
                    showFavoritesOnly.toggle()
                }
                Spacer(minLength: 0)
            }
            SoftActionButton(title: "Dinner dice", systemImage: "dice.fill") {
                showDice = true
            }
            HStack(spacing: 8) {
                NavigationLink {
                    MealBoardView()
                } label: {
                    chipLabel("Meal board", "calendar")
                }
                .buttonStyle(.plain)
                NavigationLink {
                    PrepAheadView()
                } label: {
                    chipLabel("Prep ahead", "moon.fill")
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RecipeSortOrder.allCases) { order in
                        Button {
                            store.setSortOrder(order)
                        } label: {
                            Text(order.label)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(store.recipeSortOrder == order ? Color.white : Palette.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule().fill(store.recipeSortOrder == order ? Palette.primary : Palette.card)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if hasActiveFilters {
                SoftActionButton(title: "Clear filters", systemImage: "arrow.uturn.backward") {
                    searchText = ""
                    showFavoritesOnly = false
                    selectedTags = []
                    selectedPaces = []
                    selectedSlots = []
                }
            }
        }
    }

    private func chipLabel(_ title: String, _ symbol: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
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

    private var spotlightCard: some View {
        let plates = store.catalog.filter { recipe in KitchenSpotlight.matches(recipe) }
        return CookbookCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(KitchenSpotlight.title)
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundColor(Palette.ink)
                Text(KitchenSpotlight.subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(Palette.muted)
                ForEach(plates.prefix(3)) { recipe in
                    NavigationLink(value: recipe.id) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recipe.title)
                                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                                    .foregroundColor(Palette.ink)
                                Text(KitchenFormat.minutesLabel(recipe.minutes))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(Palette.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Palette.muted)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var cookAgainCard: some View {
        let recents = store.recentlyCookedRecipes()
        return Group {
            if recents.isEmpty == false {
                CookbookCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Make this again")
                            .font(.system(.title3, design: .serif).weight(.bold))
                            .foregroundColor(Palette.ink)
                        Text("Restock the market and start timers in one tap.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Palette.muted)
                        ForEach(recents) { recipe in
                            HStack {
                                NavigationLink(value: recipe.id) {
                                    Text(recipe.title)
                                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                                        .foregroundColor(Palette.ink)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                Button("Again") {
                                    _ = store.cookAgain(recipe)
                                }
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundColor(Palette.primary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var hasActiveFilters: Bool {
        showFavoritesOnly
            || selectedTags.isEmpty == false
            || selectedPaces.isEmpty == false
            || selectedSlots.isEmpty == false
            || searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private var visibleRecipes: [Recipe] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = store.catalog.filter { recipe in
            if showFavoritesOnly && store.isFavorite(recipe.id) == false {
                return false
            }
            if selectedTags.isEmpty == false {
                let recipeTags = Set(recipe.dietTags)
                if selectedTags.isSubset(of: recipeTags) == false {
                    return false
                }
            }
            if selectedPaces.isEmpty == false && selectedPaces.contains(recipe.pace) == false {
                return false
            }
            if selectedSlots.isEmpty == false && selectedSlots.contains(recipe.slot) == false {
                return false
            }
            if query.isEmpty == false {
                let titleHit = recipe.title.lowercased().contains(query)
                let summaryHit = recipe.summary.lowercased().contains(query)
                let ingredientHit = recipe.ingredients.contains { item in
                    item.name.lowercased().contains(query)
                }
                if titleHit == false && summaryHit == false && ingredientHit == false {
                    return false
                }
            }
            return true
        }
        return filtered.sorted { lhs, rhs in
            switch store.recipeSortOrder {
            case .name:
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            case .pace:
                if lhs.pace.sortIndex == rhs.pace.sortIndex {
                    return lhs.title < rhs.title
                }
                return lhs.pace.sortIndex < rhs.pace.sortIndex
            case .mealSlot:
                if lhs.slot.sortIndex == rhs.slot.sortIndex {
                    return lhs.title < rhs.title
                }
                return lhs.slot.sortIndex < rhs.slot.sortIndex
            case .favoritesFirst:
                let leftFav = store.isFavorite(lhs.id)
                let rightFav = store.isFavorite(rhs.id)
                if leftFav == rightFav {
                    return lhs.title < rhs.title
                }
                return leftFav && rightFav == false
            }
        }
    }
}
