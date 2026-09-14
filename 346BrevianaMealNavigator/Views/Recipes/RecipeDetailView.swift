import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let recipe: Recipe

    @State private var feedback: String?
    @State private var showTimerConfirm = false
    @State private var servings: Int
    @State private var noteText: String
    @State private var showPinSheet = false

    init(recipe: Recipe) {
        self.recipe = recipe
        _servings = State(initialValue: recipe.servings)
        _noteText = State(initialValue: "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BannerHeader(
                    imageName: "BannerPasta",
                    title: recipe.title,
                    subtitle: recipe.summary
                )

                if let feedback {
                    FeedbackBanner(text: feedback)
                }

                metaCard
                pantryCard
                swapCard
                ingredientsCard
                notesCard
                stepsCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .kitchenScreen()
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    store.toggleFavorite(recipe.id)
                } label: {
                    Image(systemName: store.isFavorite(recipe.id) ? "heart.fill" : "heart")
                        .foregroundColor(Palette.onBackdrop)
                }
            }
        }
        .onAppear {
            store.markRecipeViewed(recipe.id)
            noteText = store.noteText(for: recipe.id)
        }
        .onChange(of: noteText) { newValue in
            store.setNote(for: recipe.id, text: newValue)
        }
        .alert("Replace running timers?", isPresented: $showTimerConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Start anyway") {
                beginTimers()
            }
        } message: {
            Text("This recipe already has timers on the Cook board. New steps will be added beside the ones still running.")
        }
        .sheet(isPresented: $showPinSheet) {
            PinToBoardSheet(recipe: recipe) { message in
                feedback = message
            }
            .environmentObject(store)
        }
    }

    private var scale: Double {
        guard recipe.servings > 0 else { return 1 }
        return Double(servings) / Double(recipe.servings)
    }

    private var pantryCovered: Int {
        store.pantryCoverCount(for: recipe)
    }

    private var metaCard: some View {
        CookbookCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    PaceChip(pace: recipe.pace)
                    Text(recipe.slot.label)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(Palette.muted)
                    Text(KitchenFormat.minutesLabel(recipe.minutes))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(Palette.muted)
                }
                if recipe.dietTags.isEmpty == false {
                    FlexibleChipRow(tags: recipe.dietTags)
                }

                HStack {
                    Text("Servings")
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(Palette.ink)
                    Spacer()
                    Button {
                        servings = max(1, servings - 1)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Palette.primary)
                    }
                    .buttonStyle(.plain)
                    Text("\(servings)")
                        .font(.system(.title3, design: .serif).weight(.bold))
                        .foregroundColor(Palette.ink)
                        .frame(minWidth: 28)
                    Button {
                        servings = min(12, servings + 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Palette.primary)
                    }
                    .buttonStyle(.plain)
                }
                if servings != recipe.servings {
                    Text("Quantities scaled from \(recipe.servings) servings.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Palette.muted)
                }
            }
        }
    }

    private var pantryCard: some View {
        CookbookCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pantry coverage")
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundColor(Palette.ink)
                Text("\(pantryCovered) of \(recipe.ingredients.count) ingredients already on the shelf.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(Palette.muted)
                let missing = store.missingIngredients(for: recipe)
                if missing.isEmpty {
                    Text("You can cook this without a market run.")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundColor(Palette.primary)
                } else {
                    Text("Still need: " + missing.map(\.name).joined(separator: ", "))
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(Palette.ink)
                }
            }
        }
    }

    private var ingredientsCard: some View {
        CookbookCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ingredients")
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundColor(Palette.ink)

                ForEach(recipe.ingredients) { item in
                    HStack {
                        Text(item.name)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Palette.ink)
                        Spacer()
                        Text(KitchenFormat.quantity(item.quantity * scale, unit: item.unit))
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(Palette.primary)
                    }
                    .padding(.vertical, 4)
                }

                GradientActionButton(title: "Add Ingredients to List", systemImage: "basket.fill") {
                    let result = store.addIngredientsToList(from: scaledRecipe)
                    feedback = result.message
                }

                SoftActionButton(title: "Open Market", systemImage: "arrow.right.circle") {
                    store.openMarket()
                }
                SoftActionButton(title: "Pin to meal board", systemImage: "calendar") {
                    showPinSheet = true
                }
                SoftActionButton(title: "Save leftovers", systemImage: "refrigerator.fill") {
                    feedback = store.saveLeftovers(from: recipe)
                }
                SoftActionButton(title: "Make this again", systemImage: "arrow.counterclockwise") {
                    feedback = store.cookAgain(scaledRecipe)
                }
            }
        }
    }

    private var swapCard: some View {
        let swaps = IngredientSwapBook.swaps(in: recipe)
        return Group {
            if swaps.isEmpty == false {
                CookbookCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("If you are out")
                            .font(.system(.title3, design: .serif).weight(.bold))
                            .foregroundColor(Palette.ink)
                        Text("Swap an ingredient before it hits the Market list.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Palette.muted)
                        ForEach(swaps) { swap in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(swap.original)
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundColor(Palette.ink)
                                    Text("Try \(swap.replacement)")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(Palette.muted)
                                }
                                Spacer()
                                Button(store.isSwapActive(original: swap.original, replacement: swap.replacement) ? "Using swap" : "Use swap") {
                                    store.toggleSwap(original: swap.original, replacement: swap.replacement)
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

    private var notesCard: some View {
        CookbookCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Cook notes")
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundColor(Palette.ink)
                Text("Salt level, kid swaps, and what to skip next time.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Palette.muted)
                KitchenNoteEditor(placeholder: "Hold the honey, extra lemon...", text: $noteText)
            }
        }
    }

    private var stepsCard: some View {
        CookbookCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Cook steps")
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundColor(Palette.ink)

                ForEach(Array(recipe.steps.enumerated()), id: \.element.id) { index, step in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(index + 1). \(step.title)")
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(Palette.ink)
                            Spacer()
                            Text(KitchenFormat.clock(step.durationSeconds))
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundColor(Palette.muted)
                        }
                        Text(step.detail)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Palette.muted)
                        if step.durationSeconds > 0 {
                            Button {
                                feedback = store.startSingleTimer(recipe: recipe, step: step)
                            } label: {
                                Text("Start this timer")
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundColor(Palette.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }

                GradientActionButton(title: "Start step timers", systemImage: "timer") {
                    if hasOpenTimers {
                        showTimerConfirm = true
                    } else {
                        beginTimers()
                    }
                }
            }
        }
    }

    private var hasOpenTimers: Bool {
        store.activeTimers.contains { timer in
            timer.recipeId == recipe.id && timer.isFinished == false
        }
    }

    private var scaledRecipe: Recipe {
        var copy = recipe
        copy.servings = servings
        copy.ingredients = recipe.ingredients.map { item in
            var next = item
            next.quantity = item.quantity * scale
            return next
        }
        return copy
    }

    private func beginTimers() {
        let result = store.startTimers(from: recipe)
        feedback = result.message
        if result.started > 0 {
            store.openCook()
        }
    }
}

private struct FlexibleChipRow: View {
    let tags: [DietTag]

    var body: some View {
        HStack {
            ForEach(tags) { tag in
                DietChip(tag: tag)
            }
        }
    }
}
