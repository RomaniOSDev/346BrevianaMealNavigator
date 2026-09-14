import SwiftUI
import UIKit

struct GroceryEditorSheet: View {
    enum Mode: Identifiable {
        case create
        case edit(GroceryItem)

        var id: String {
            switch self {
            case .create:
                return "create"
            case .edit(let item):
                return item.id.uuidString
            }
        }
    }

    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let mode: Mode

    @State private var name = ""
    @State private var quantityText = "1"
    @State private var unit = ""
    @State private var category: GroceryCategory = .produce
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CookbookCard {
                        VStack(alignment: .leading, spacing: 12) {
                            if showsIdentityFields {
                                labeledField("Item name", text: $name, placeholder: "Baby spinach")
                            }
                            labeledField("Quantity", text: $quantityText, placeholder: "2", keyboard: .decimalPad)
                            labeledField("Unit", text: $unit, placeholder: "cups")

                            if showsIdentityFields {
                                Text("Category")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundColor(Palette.muted)
                                Picker("Category", selection: $category) {
                                    ForEach(GroceryCategory.allCases) { item in
                                        Text(item.label).tag(item)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            if let errorText {
                                Text(errorText)
                                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                                    .foregroundColor(Palette.primary)
                            }
                        }
                    }

                    GradientActionButton(title: saveTitle, systemImage: "checkmark") {
                        save()
                    }
                }
                .padding(18)
            }
            .kitchenScreen()
            .navigationTitle(navigationTitle)
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
                populate()
            }
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .create:
            return "Add market item"
        case .edit:
            return "Edit quantity"
        }
    }

    private var saveTitle: String {
        switch mode {
        case .create:
            return "Add to Market"
        case .edit:
            return "Save quantity"
        }
    }

    private var showsIdentityFields: Bool {
        switch mode {
        case .create:
            return true
        case .edit:
            return false
        }
    }

    private func labeledField(_ title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(Palette.muted)
            KitchenTextField(placeholder: placeholder, text: text, keyboard: keyboard)
        }
    }

    private func populate() {
        switch mode {
        case .create:
            name = ""
            quantityText = "1"
            unit = ""
            category = .produce
        case .edit(let item):
            name = item.name
            quantityText = trimmedNumber(item.quantity)
            unit = item.unit
            category = item.category
        }
    }

    private func trimmedNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "1"
    }

    private func parsedQuantity() -> Double? {
        let normalized = quantityText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if let value = Double(normalized), value > 0 {
            return value
        }
        return nil
    }

    private func save() {
        guard let quantity = parsedQuantity() else {
            errorText = "Enter a quantity greater than zero."
            return
        }
        switch mode {
        case .create:
            if let message = store.addCustomGrocery(name: name, quantity: quantity, unit: unit, category: category) {
                errorText = message
                return
            }
        case .edit(let item):
            if store.updateGroceryQuantity(id: item.id, quantity: quantity, unit: unit) == false {
                errorText = "Could not update that item."
                return
            }
        }
        dismiss()
    }
}
