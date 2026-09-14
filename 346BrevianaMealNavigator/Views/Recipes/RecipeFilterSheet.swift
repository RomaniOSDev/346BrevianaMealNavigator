import SwiftUI

struct RecipeFilterSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedTags: Set<DietTag>
    @Binding var selectedPaces: Set<MealPace>
    @Binding var selectedSlots: Set<MealSlot>

    @State private var draftTags: Set<DietTag> = []
    @State private var draftPaces: Set<MealPace> = []
    @State private var draftSlots: Set<MealSlot> = []
    @State private var feedback: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let feedback {
                        FeedbackBanner(text: feedback)
                    }

                    filterBlock(title: "Dietary tags") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                            ForEach(DietTag.allCases) { tag in
                                chip(title: tag.label, selected: draftTags.contains(tag)) {
                                    toggle(tag, in: &draftTags)
                                }
                            }
                        }
                    }

                    filterBlock(title: "Pace") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                            ForEach(MealPace.allCases) { pace in
                                chip(title: pace.label, selected: draftPaces.contains(pace)) {
                                    toggle(pace, in: &draftPaces)
                                }
                            }
                        }
                    }

                    filterBlock(title: "Meal") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                            ForEach(MealSlot.allCases) { slot in
                                chip(title: slot.label, selected: draftSlots.contains(slot)) {
                                    toggle(slot, in: &draftSlots)
                                }
                            }
                        }
                    }

                    GradientActionButton(title: "Apply filters", systemImage: "checkmark") {
                        selectedTags = draftTags
                        selectedPaces = draftPaces
                        selectedSlots = draftSlots
                        dismiss()
                    }

                    SoftActionButton(title: "Save as my kitchen prefs", systemImage: "square.and.arrow.down") {
                        store.setDietaryPreferences(Array(draftTags))
                        feedback = "Dietary preferences saved."
                    }

                    SoftActionButton(title: "Clear draft", systemImage: "eraser") {
                        draftTags = []
                        draftPaces = []
                        draftSlots = []
                    }
                }
                .padding(18)
            }
            .kitchenScreen()
            .navigationTitle("Dietary filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Palette.onBackdrop)
                }
            }
            .onAppear {
                draftTags = selectedTags
                draftPaces = selectedPaces
                draftSlots = selectedSlots
            }
        }
    }

    private func filterBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        CookbookCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundColor(Palette.ink)
                content()
            }
        }
    }

    private func chip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(selected ? Color.white : Palette.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(selected ? Palette.primary : Palette.fieldFill)
                )
        }
        .buttonStyle(.plain)
    }

    private func toggle<T: Hashable>(_ value: T, in set: inout Set<T>) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }
}
