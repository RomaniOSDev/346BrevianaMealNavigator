import SwiftUI
import UIKit

struct StaplesSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var quantityText = "1"
    @State private var unit = "bottle"
    @State private var category: GroceryCategory = .pantry
    @State private var intervalText = "7"
    @State private var errorText: String?
    @State private var feedback: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BannerHeader(
                        imageName: "BannerGroceries",
                        title: "Weekly staples",
                        subtitle: "Olive oil, eggs, and butter drop onto Market when their week is up."
                    )

                    if let feedback {
                        FeedbackBanner(text: feedback)
                    }

                    CookbookCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Add a repeating staple")
                                .font(.system(.title3, design: .serif).weight(.bold))
                                .foregroundColor(Palette.ink)
                            KitchenTextField(placeholder: "Olive oil", text: $name)
                            KitchenTextField(placeholder: "1", text: $quantityText, keyboard: .decimalPad)
                            KitchenTextField(placeholder: "bottle", text: $unit)
                            KitchenTextField(placeholder: "7", text: $intervalText, keyboard: .numberPad)
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
                            GradientActionButton(title: "Save staple", systemImage: "plus") {
                                save()
                            }
                        }
                    }

                    if store.dueStapleRules.isEmpty == false {
                        GradientActionButton(title: "Drop due staples on Market", systemImage: "basket.fill") {
                            feedback = store.dropDueStaples()
                        }
                    }

                    ForEach(store.stapleRules) { rule in
                        CookbookCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(rule.name)
                                        .font(.system(.headline, design: .serif))
                                        .foregroundColor(Palette.ink)
                                    Text("\(KitchenFormat.quantity(rule.quantity, unit: rule.unit)) · every \(rule.intervalDays) days")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(Palette.muted)
                                }
                                Spacer()
                                Button("Remove") {
                                    store.deleteStapleRule(rule.id)
                                }
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundColor(Palette.primary)
                            }
                        }
                    }
                }
                .padding(18)
            }
            .kitchenScreen()
            .navigationTitle("Staples")
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

    private func save() {
        let quantity = Double(quantityText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let days = Int(intervalText) ?? 7
        if let message = store.addStapleRule(name: name, quantity: quantity, unit: unit, category: category, intervalDays: days) {
            errorText = message
            return
        }
        errorText = nil
        feedback = "Saved \(name.trimmingCharacters(in: .whitespacesAndNewlines))."
        name = ""
        quantityText = "1"
        unit = "bottle"
        intervalText = "7"
    }
}
