import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var editingItem: GroceryItem?
    @State private var showAddItem = false
    @State private var showPantry = false
    @State private var pendingDelete: GroceryItem?
    @State private var showClearConfirm = false
    @State private var showStaples = false
    @State private var feedback: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    headerSection
                    if store.groceryList.isEmpty {
                        emptySection
                    } else {
                        ForEach(GroceryCategory.allCases) { category in
                            let items = store.groceryList.filter { item in item.category == category }
                            if items.isEmpty == false {
                                Section {
                                    ForEach(items) { item in
                                        groceryRow(item)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button {
                                                    store.toggleAcquired(item.id)
                                                    feedback = item.isAcquired ? "Returned \(item.name) to the list." : "Marked \(item.name) as acquired."
                                                } label: {
                                                    Label(item.isAcquired ? "Undo" : "Got it", systemImage: "checkmark.circle.fill")
                                                }
                                                .tint(Palette.accent)
                                            }
                                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.clear)
                                    }
                                } header: {
                                    Label(category.label, systemImage: category.symbol)
                                        .font(.system(.title3, design: .serif).weight(.bold))
                                        .foregroundColor(Palette.onBackdrop)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .kitchenScreen()
            .navigationTitle("Market")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { recipeID in
                if let recipe = store.recipe(id: recipeID) {
                    RecipeDetailView(recipe: recipe)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Pantry") {
                        showPantry = true
                    }
                    .foregroundColor(Palette.onBackdrop)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showAddItem = true
                    }
                    .foregroundColor(Palette.onBackdrop)
                }
            }
            .sheet(item: $editingItem) { item in
                GroceryEditorSheet(mode: .edit(item))
                    .environmentObject(store)
            }
            .sheet(isPresented: $showAddItem) {
                GroceryEditorSheet(mode: .create)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showPantry) {
                PantrySheet()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showStaples) {
                StaplesSheet()
                    .environmentObject(store)
            }
            .alert("Remove this item?", isPresented: deleteAlertBinding) {
                Button("Cancel", role: .cancel) {
                    pendingDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let pendingDelete {
                        store.deleteGrocery(pendingDelete.id)
                        feedback = "Removed \(pendingDelete.name)."
                    }
                    pendingDelete = nil
                }
            } message: {
                Text("This item will leave the Market list.")
            }
            .alert("Clear acquired items?", isPresented: $showClearConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    store.clearAcquiredGroceries()
                    feedback = "Acquired items were cleared."
                }
            } message: {
                Text("Items already marked as acquired will be removed.")
            }
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { isPresented in
                if isPresented == false {
                    pendingDelete = nil
                }
            }
        )
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                BannerHeader(
                    imageName: "BannerGroceries",
                    title: "Market List",
                    subtitle: "Built from recipes, minus what the pantry already holds."
                )
                progressCard
                if store.dueStapleRules.isEmpty == false {
                    CookbookCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Staples due")
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(Palette.ink)
                            Text(store.dueStapleRules.map(\.name).joined(separator: ", "))
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(Palette.muted)
                            GradientActionButton(title: "Drop due staples", systemImage: "basket.fill") {
                                feedback = store.dropDueStaples()
                            }
                        }
                    }
                }
                HStack(spacing: 8) {
                    SoftActionButton(title: "Weekly staples", systemImage: "arrow.triangle.2.circlepath") {
                        showStaples = true
                    }
                    NavigationLink {
                        LeftoversView()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "refrigerator.fill")
                            Text("Leftovers")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        }
                        .foregroundColor(Palette.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Palette.card)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Palette.primary.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                if let feedback {
                    FeedbackBanner(text: feedback)
                }
                if store.groceryList.contains(where: { item in item.isAcquired }) {
                    SoftActionButton(title: "Clear acquired", systemImage: "trash") {
                        showClearConfirm = true
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    private var emptySection: some View {
        Section {
            EmptyStateView(
                symbol: "basket",
                title: "The market basket is empty",
                message: "Open a recipe and tap Add Ingredients to List. Pantry staples stay home.",
                actionTitle: "Browse recipes"
            ) {
                store.requestedTab = .recipes
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    private var progressCard: some View {
        CookbookCard {
            let total = store.groceryList.count
            let got = store.groceryList.filter { item in item.isAcquired }.count
            VStack(alignment: .leading, spacing: 8) {
                Text(total == 0 ? "No items yet" : "\(got) of \(total) acquired")
                    .font(.system(.headline, design: .serif))
                    .foregroundColor(Palette.ink)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Palette.fieldFill)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Palette.primary, Palette.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: barWidth(in: geo.size.width, got: got, total: total))
                    }
                }
                .frame(height: 10)
            }
        }
    }

    private func barWidth(in totalWidth: CGFloat, got: Int, total: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        let ratio = CGFloat(got) / CGFloat(total)
        return max(0, min(totalWidth, totalWidth * ratio))
    }

    private func groceryRow(_ item: GroceryItem) -> some View {
        CookbookCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Button {
                        store.toggleAcquired(item.id)
                    } label: {
                        Image(systemName: item.isAcquired ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(item.isAcquired ? Palette.primary : Palette.accent)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(.headline, design: .serif))
                            .foregroundColor(Palette.ink)
                            .strikethrough(item.isAcquired)
                        Text(KitchenFormat.quantity(item.quantity, unit: item.unit))
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(Palette.muted)
                        Text(item.sourceRecipeTitle)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Palette.muted)
                    }
                    Spacer(minLength: 8)
                }

                HStack(spacing: 8) {
                    SoftActionButton(title: "Edit qty", systemImage: "pencil") {
                        editingItem = item
                    }
                    SoftActionButton(title: "Remove", systemImage: "trash") {
                        pendingDelete = item
                    }
                }
            }
        }
    }
}
