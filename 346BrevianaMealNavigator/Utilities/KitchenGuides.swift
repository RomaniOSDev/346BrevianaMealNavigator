import Foundation

struct IngredientSwap: Identifiable, Equatable {
    var id: String { original.lowercased() }
    let original: String
    let replacement: String
}

enum IngredientSwapBook {
    static let pairs: [IngredientSwap] = [
        IngredientSwap(original: "Greek yogurt", replacement: "Plain yogurt"),
        IngredientSwap(original: "Honey", replacement: "Maple syrup"),
        IngredientSwap(original: "Butter", replacement: "Olive oil"),
        IngredientSwap(original: "Sliced bread", replacement: "Tortillas"),
        IngredientSwap(original: "Flour tortillas", replacement: "Corn tortillas"),
        IngredientSwap(original: "Hummus", replacement: "Mashed avocado"),
        IngredientSwap(original: "Cooked chicken", replacement: "Chickpeas"),
        IngredientSwap(original: "Egg noodles", replacement: "Rice"),
        IngredientSwap(original: "Parmesan", replacement: "Nutritional yeast"),
        IngredientSwap(original: "Salmon fillets", replacement: "Cod fillets"),
        IngredientSwap(original: "Ground turkey", replacement: "Black beans"),
        IngredientSwap(original: "Cheddar", replacement: "Mozzarella"),
        IngredientSwap(original: "Long-grain rice", replacement: "Quinoa"),
        IngredientSwap(original: "White rice", replacement: "Couscous")
    ]

    static func swaps(in recipe: Recipe) -> [IngredientSwap] {
        let names = Set(recipe.ingredients.map { item in item.name.lowercased() })
        return pairs.filter { swap in names.contains(swap.original.lowercased()) }
    }
}

enum PrepPlan {
    static func tasks(for recipe: Recipe) -> [PrepTask] {
        var made: [PrepTask] = []
        for ingredient in recipe.ingredients {
            let name = ingredient.name
            let lower = name.lowercased()
            if lower.contains("chicken") || lower.contains("turkey") || lower.contains("salmon") {
                made.append(task("Thaw \(name)", "Move it to the fridge tonight so dinner is not late.", recipe))
            }
            if lower.contains("onion") || lower.contains("carrot") || lower.contains("celery") || lower.contains("lettuce") || lower.contains("tomato") || lower.contains("chive") {
                made.append(task("Chop \(name)", "Board work the night before keeps the cook window short.", recipe))
            }
            if lower.contains("rice") || lower.contains("chickpea") || lower.contains("bean") {
                made.append(task("Rinse \(name)", "Drain and ready the pot so simmer time is honest.", recipe))
            }
        }
        if made.isEmpty {
            made.append(task("Set out tools for \(recipe.title)", "Bowls, board, and pan ready before anyone is hungry.", recipe))
        }
        return made
    }

    private static func task(_ title: String, _ detail: String, _ recipe: Recipe) -> PrepTask {
        PrepTask(
            id: UUID(),
            title: title,
            detail: detail,
            recipeId: recipe.id,
            recipeTitle: recipe.title,
            isDone: false
        )
    }
}

enum KitchenSpotlight {
    static var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday == 1 || weekday == 7
    }

    static var title: String {
        isWeekend ? "Weekend table" : "Weeknight rush"
    }

    static var subtitle: String {
        isWeekend
            ? "Family-paced plates for a slower, crowded table."
            : "Quick cards that land before backpacks hit the floor."
    }

    static func matches(_ recipe: Recipe) -> Bool {
        if isWeekend {
            return recipe.pace == .family
        }
        return recipe.pace == .quick
    }
}
