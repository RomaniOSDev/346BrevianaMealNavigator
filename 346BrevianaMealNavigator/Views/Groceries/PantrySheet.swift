import SwiftUI

struct PantrySheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: GroceryCategory = .pantry
    @State private var errorText: String?
    @State private var pendingDelete: PantryItem?
    @State private var feedback: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BannerHeader(
                        imageName: "BannerGroceries",
                        title: "Pantry shelf",
                        subtitle: "Items here are skipped when a recipe fills the Market list."
                    )

                    if let feedback {
                        FeedbackBanner(text: feedback)
                    }

                    CookbookCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Add a staple")
                                .font(.system(.title3, design: .serif).weight(.bold))
                                .foregroundColor(Palette.ink)
                            KitchenTextField(placeholder: "Olive oil", text: $name)
                            Picker("Category", selection: $category) {
                                ForEach(GroceryCategory.allCases) { item in
                                    Text(item.label).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)
                            if let errorText {
                                Text(errorText)
                                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                                    .foregroundColor(Palette.primary)
                            }
                            GradientActionButton(title: "Add to pantry", systemImage: "plus") {
                                if let message = store.addPantryItem(name: name, category: category) {
                                    errorText = message
                                } else {
                                    errorText = nil
                                    feedback = "Added \(name.trimmingCharacters(in: .whitespacesAndNewlines))."
                                    name = ""
                                }
                            }
                        }
                    }

                    if store.pantryItems.isEmpty {
                        EmptyStateView(
                            symbol: "shippingbox",
                            title: "Pantry is empty",
                            message: "Add staples you already keep at home so grocery lists stay lean."
                        )
                    } else {
                        ForEach(GroceryCategory.allCases) { group in
                            let items = store.pantryItems.filter { item in item.category == group }
                            if items.isEmpty == false {
                                CookbookCard {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Label(group.label, systemImage: group.symbol)
                                            .font(.system(.headline, design: .serif))
                                            .foregroundColor(Palette.ink)
                                        ForEach(items) { item in
                                            HStack {
                                                Text(item.name)
                                                    .font(.system(.body, design: .rounded))
                                                    .foregroundColor(Palette.ink)
                                                Spacer()
                                                Button("Remove") {
                                                    pendingDelete = item
                                                }
                                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                                .foregroundColor(Palette.primary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(18)
            }
            .kitchenScreen()
            .navigationTitle("Pantry")
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
            .alert("Remove pantry item?", isPresented: deleteAlertBinding) {
                Button("Cancel", role: .cancel) {
                    pendingDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let pendingDelete {
                        store.deletePantryItem(pendingDelete.id)
                        feedback = "Removed \(pendingDelete.name) from the pantry."
                    }
                    pendingDelete = nil
                }
            } message: {
                Text("Recipes will start listing this ingredient again.")
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
}
