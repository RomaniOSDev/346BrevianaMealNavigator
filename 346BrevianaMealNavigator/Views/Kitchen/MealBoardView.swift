import SwiftUI

struct MealBoardView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var picker: SlotPick?
    @State private var feedback: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BannerHeader(
                    imageName: "BannerPasta",
                    title: "Meal board",
                    subtitle: "Pin breakfast, lunch, and dinner for the next seven days."
                )

                if let feedback {
                    FeedbackBanner(text: feedback)
                }

                ForEach(BoardDay.orderedWeekdays, id: \.self) { weekday in
                    dayCard(weekday)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .kitchenScreen()
        .navigationTitle("Meal board")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationDestination(for: UUID.self) { recipeID in
            if let recipe = store.recipe(id: recipeID) {
                RecipeDetailView(recipe: recipe)
            }
        }
        .sheet(item: $picker) { pick in
            RecipePickSheet(slot: pick.slot) { recipe in
                store.pinToBoard(recipeId: recipe.id, weekday: pick.weekday, slot: pick.slot)
                picker = nil
            }
            .environmentObject(store)
        }
    }

    private func dayCard(_ weekday: Int) -> some View {
        CookbookCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(BoardDay.fullLabel(weekday))
                        .font(.system(.title3, design: .serif).weight(.bold))
                        .foregroundColor(Palette.ink)
                    if weekday == BoardDay.today {
                        Text("Today")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                    }
                    Spacer()
                    Button("Shop day") {
                        feedback = store.shopPinnedDay(weekday)
                        store.openMarket()
                    }
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(Palette.primary)
                }

                ForEach(MealSlot.allCases) { slot in
                    slotRow(weekday: weekday, slot: slot)
                }
            }
        }
    }

    private func slotRow(weekday: Int, slot: MealSlot) -> some View {
        let pin = store.boardPin(weekday: weekday, slot: slot)
        let recipe = pin.flatMap { store.recipe(id: $0.recipeId) }
        return HStack(alignment: .center, spacing: 10) {
            Text(slot.label)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(Palette.muted)
                .frame(width: 72, alignment: .leading)
            if let recipe {
                NavigationLink(value: recipe.id) {
                    Text(recipe.title)
                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundColor(Palette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button {
                    if let pin {
                        store.unpinFromBoard(pin.id)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Palette.primary)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    picker = SlotPick(weekday: weekday, slot: slot)
                } label: {
                    Text("Pin a plate")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(Palette.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct SlotPick: Identifiable {
    var id: String { "\(weekday)-\(slot.rawValue)" }
    let weekday: Int
    let slot: MealSlot
}

struct RecipePickSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let slot: MealSlot
    let onPick: (Recipe) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(store.catalog.filter { recipe in recipe.slot == slot }) { recipe in
                        Button {
                            onPick(recipe)
                            dismiss()
                        } label: {
                            RecipeOverviewCard(recipe: recipe, isFavorite: store.isFavorite(recipe.id))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
            .kitchenScreen()
            .navigationTitle(slot.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Palette.onBackdrop)
                }
            }
        }
    }
}

struct PinToBoardSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    var onPinned: (String) -> Void

    @State private var weekday = BoardDay.today
    @State private var slot: MealSlot

    init(recipe: Recipe, onPinned: @escaping (String) -> Void) {
        self.recipe = recipe
        self.onPinned = onPinned
        _slot = State(initialValue: recipe.slot)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                CookbookCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Day")
                            .font(.system(.headline, design: .serif))
                            .foregroundColor(Palette.ink)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(BoardDay.orderedWeekdays, id: \.self) { day in
                                    Button {
                                        weekday = day
                                    } label: {
                                        Text(BoardDay.label(day))
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundColor(weekday == day ? Color.white : Palette.ink)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Capsule().fill(weekday == day ? Palette.primary : Palette.fieldFill))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        Text("Meal")
                            .font(.system(.headline, design: .serif))
                            .foregroundColor(Palette.ink)
                        Picker("Meal", selection: $slot) {
                            ForEach(MealSlot.allCases) { item in
                                Text(item.label).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                GradientActionButton(title: "Pin to board", systemImage: "calendar") {
                    store.pinToBoard(recipeId: recipe.id, weekday: weekday, slot: slot)
                    onPinned("Pinned \(recipe.title) to \(BoardDay.fullLabel(weekday)) \(slot.label.lowercased()).")
                    dismiss()
                }
                Spacer()
            }
            .padding(18)
            .kitchenScreen()
            .navigationTitle("Pin plate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Palette.onBackdrop)
                }
            }
        }
    }
}
