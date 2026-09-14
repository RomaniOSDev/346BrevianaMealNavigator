import Foundation

enum MealPace: String, Codable, CaseIterable, Identifiable, Hashable {
    case quick
    case balanced
    case family

    var id: String { rawValue }

    var label: String {
        switch self {
        case .quick:
            return "Quick"
        case .balanced:
            return "Balanced"
        case .family:
            return "Family"
        }
    }

    var symbol: String {
        switch self {
        case .quick:
            return "bolt.fill"
        case .balanced:
            return "leaf.fill"
        case .family:
            return "person.3.fill"
        }
    }

    var sortIndex: Int {
        switch self {
        case .quick:
            return 0
        case .balanced:
            return 1
        case .family:
            return 2
        }
    }
}

enum MealSlot: String, Codable, CaseIterable, Identifiable, Hashable {
    case breakfast
    case lunch
    case dinner

    var id: String { rawValue }

    var label: String {
        switch self {
        case .breakfast:
            return "Breakfast"
        case .lunch:
            return "Lunch"
        case .dinner:
            return "Dinner"
        }
    }

    var sortIndex: Int {
        switch self {
        case .breakfast:
            return 0
        case .lunch:
            return 1
        case .dinner:
            return 2
        }
    }
}

enum DietTag: String, Codable, CaseIterable, Identifiable, Hashable {
    case vegetarian
    case vegan
    case glutenFree
    case dairyFree
    case nutFree
    case kidFriendly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .vegetarian:
            return "Vegetarian"
        case .vegan:
            return "Vegan"
        case .glutenFree:
            return "Gluten Free"
        case .dairyFree:
            return "Dairy Free"
        case .nutFree:
            return "Nut Free"
        case .kidFriendly:
            return "Kid Friendly"
        }
    }
}

enum GroceryCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case produce
    case dairy
    case meats
    case pantry

    var id: String { rawValue }

    var label: String {
        switch self {
        case .produce:
            return "Produce"
        case .dairy:
            return "Dairy"
        case .meats:
            return "Meats"
        case .pantry:
            return "Pantry"
        }
    }

    var symbol: String {
        switch self {
        case .produce:
            return "leaf.fill"
        case .dairy:
            return "cup.and.saucer.fill"
        case .meats:
            return "fork.knife"
        case .pantry:
            return "shippingbox.fill"
        }
    }
}

enum RecipeSortOrder: String, Codable, CaseIterable, Identifiable {
    case name
    case pace
    case mealSlot
    case favoritesFirst

    var id: String { rawValue }

    var label: String {
        switch self {
        case .name:
            return "Name"
        case .pace:
            return "Pace"
        case .mealSlot:
            return "Meal"
        case .favoritesFirst:
            return "Favorites first"
        }
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case recipes
    case market
    case cook
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recipes:
            return "Recipes"
        case .market:
            return "Market"
        case .cook:
            return "Cook"
        case .more:
            return "More"
        }
    }

    var symbol: String {
        switch self {
        case .recipes:
            return "book.closed.fill"
        case .market:
            return "basket.fill"
        case .cook:
            return "timer"
        case .more:
            return "ellipsis.circle.fill"
        }
    }
}

struct RecipeIngredient: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var category: GroceryCategory
}

struct RecipeStep: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var detail: String
    var durationSeconds: Int
}

struct Recipe: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var summary: String
    var pace: MealPace
    var slot: MealSlot
    var dietTags: [DietTag]
    var servings: Int
    var minutes: Int
    var ingredients: [RecipeIngredient]
    var steps: [RecipeStep]
}

struct GroceryItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var category: GroceryCategory
    var isAcquired: Bool
    var sourceRecipeTitle: String
}

struct PantryItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var category: GroceryCategory
}

struct CookTimer: Identifiable, Codable, Equatable {
    var id: UUID
    var recipeId: UUID
    var recipeTitle: String
    var stepTitle: String
    var totalSeconds: Int
    var remainingSeconds: Int
    var isPaused: Bool
    var wasRunningBeforeScenePause: Bool

    var isFinished: Bool {
        remainingSeconds <= 0
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 1 }
        let consumed = Double(totalSeconds - remainingSeconds)
        let ratio = consumed / Double(totalSeconds)
        if ratio < 0 { return 0 }
        if ratio > 1 { return 1 }
        return ratio
    }
}

enum KitchenEventKind: String, Codable, Hashable {
    case cooked
    case shopped
    case acquired
}

struct KitchenEvent: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var kind: KitchenEventKind
    var recipeId: UUID?
    var recipeTitle: String
    var slot: MealSlot?
    var pace: MealPace?
    var groceryCategory: GroceryCategory?
}

struct RecipeNote: Identifiable, Codable, Equatable {
    var id: UUID
    var recipeId: UUID
    var text: String
}

struct MealBoardPin: Identifiable, Codable, Equatable {
    var id: UUID
    var weekday: Int
    var slot: MealSlot
    var recipeId: UUID
}

struct StapleRule: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var category: GroceryCategory
    var intervalDays: Int
    var lastAdded: Date?

    static let starter: [StapleRule] = [
        StapleRule(id: StableID.make("aaaa1111-1111-4111-8111-111111111111"), name: "Olive oil", quantity: 1, unit: "bottle", category: .pantry, intervalDays: 7, lastAdded: Date()),
        StapleRule(id: StableID.make("aaaa2222-2222-4222-8222-222222222222"), name: "Eggs", quantity: 12, unit: "large", category: .dairy, intervalDays: 7, lastAdded: Date()),
        StapleRule(id: StableID.make("aaaa3333-3333-4333-8333-333333333333"), name: "Butter", quantity: 1, unit: "pack", category: .dairy, intervalDays: 7, lastAdded: Date())
    ]
}

struct PrepTask: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var detail: String
    var recipeId: UUID?
    var recipeTitle: String
    var isDone: Bool
}

struct LeftoverEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var fromRecipeTitle: String
    var suggestedRecipeId: UUID?
    var suggestedRecipeTitle: String
    var createdAt: Date
}

enum BoardDay {
    static let orderedWeekdays = [2, 3, 4, 5, 6, 7, 1]

    static var today: Int {
        Calendar.current.component(.weekday, from: Date())
    }

    static var tomorrow: Int {
        let next = today + 1
        return next > 7 ? 1 : next
    }

    static func label(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "Sun"
        case 2: return "Mon"
        case 3: return "Tue"
        case 4: return "Wed"
        case 5: return "Thu"
        case 6: return "Fri"
        case 7: return "Sat"
        default: return "Day"
        }
    }

    static func fullLabel(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return "Day"
        }
    }
}

enum StableID {
    static func make(_ value: String) -> UUID {
        if let parsed = UUID(uuidString: value) {
            return parsed
        }
        return UUID()
    }
}

enum SeededCookbook {
    static let recipes: [Recipe] = [
        Recipe(
            id: StableID.make("11111111-1111-4111-8111-111111111111"),
            title: "Sunrise Yogurt Cups",
            summary: "Creamy cups with fruit and crunch, ready before backpacks are zipped.",
            pace: .quick,
            slot: .breakfast,
            dietTags: [.vegetarian, .kidFriendly],
            servings: 4,
            minutes: 8,
            ingredients: [
                RecipeIngredient(id: StableID.make("11111111-1111-4111-8111-111111111201"), name: "Greek yogurt", quantity: 3, unit: "cups", category: .dairy),
                RecipeIngredient(id: StableID.make("11111111-1111-4111-8111-111111111202"), name: "Mixed berries", quantity: 2, unit: "cups", category: .produce),
                RecipeIngredient(id: StableID.make("11111111-1111-4111-8111-111111111203"), name: "Honey", quantity: 3, unit: "tbsp", category: .pantry),
                RecipeIngredient(id: StableID.make("11111111-1111-4111-8111-111111111204"), name: "Granola", quantity: 1, unit: "cup", category: .pantry)
            ],
            steps: [
                RecipeStep(id: StableID.make("11111111-1111-4111-8111-111111111301"), title: "Spoon the yogurt", detail: "Divide yogurt into four cups.", durationSeconds: 60),
                RecipeStep(id: StableID.make("11111111-1111-4111-8111-111111111302"), title: "Add fruit", detail: "Scatter berries over each cup.", durationSeconds: 90),
                RecipeStep(id: StableID.make("11111111-1111-4111-8111-111111111303"), title: "Finish crunch", detail: "Drizzle honey and top with granola.", durationSeconds: 60)
            ]
        ),
        Recipe(
            id: StableID.make("22222222-2222-4222-8222-222222222222"),
            title: "Skillet Egg Toast",
            summary: "Crisp toast and soft eggs from one pan while the kettle boils.",
            pace: .quick,
            slot: .breakfast,
            dietTags: [.nutFree, .kidFriendly],
            servings: 2,
            minutes: 12,
            ingredients: [
                RecipeIngredient(id: StableID.make("22222222-2222-4222-8222-222222222201"), name: "Eggs", quantity: 4, unit: "large", category: .dairy),
                RecipeIngredient(id: StableID.make("22222222-2222-4222-8222-222222222202"), name: "Sliced bread", quantity: 4, unit: "slices", category: .pantry),
                RecipeIngredient(id: StableID.make("22222222-2222-4222-8222-222222222203"), name: "Butter", quantity: 2, unit: "tbsp", category: .dairy),
                RecipeIngredient(id: StableID.make("22222222-2222-4222-8222-222222222204"), name: "Chives", quantity: 2, unit: "tbsp", category: .produce)
            ],
            steps: [
                RecipeStep(id: StableID.make("22222222-2222-4222-8222-222222222301"), title: "Toast the bread", detail: "Butter the skillet and toast both sides.", durationSeconds: 240),
                RecipeStep(id: StableID.make("22222222-2222-4222-8222-222222222302"), title: "Cook the eggs", detail: "Fry eggs to a soft center.", durationSeconds: 300)
            ]
        ),
        Recipe(
            id: StableID.make("33333333-3333-4333-8333-333333333333"),
            title: "Rainbow Veggie Wraps",
            summary: "Hummus, crunch, and color rolled into lunchbox-ready wraps.",
            pace: .quick,
            slot: .lunch,
            dietTags: [.vegetarian, .kidFriendly],
            servings: 4,
            minutes: 15,
            ingredients: [
                RecipeIngredient(id: StableID.make("33333333-3333-4333-8333-333333333201"), name: "Flour tortillas", quantity: 4, unit: "large", category: .pantry),
                RecipeIngredient(id: StableID.make("33333333-3333-4333-8333-333333333202"), name: "Hummus", quantity: 1, unit: "cup", category: .pantry),
                RecipeIngredient(id: StableID.make("33333333-3333-4333-8333-333333333203"), name: "Cucumber", quantity: 1, unit: "large", category: .produce),
                RecipeIngredient(id: StableID.make("33333333-3333-4333-8333-333333333204"), name: "Carrots", quantity: 2, unit: "medium", category: .produce),
                RecipeIngredient(id: StableID.make("33333333-3333-4333-8333-333333333205"), name: "Baby spinach", quantity: 2, unit: "cups", category: .produce)
            ],
            steps: [
                RecipeStep(id: StableID.make("33333333-3333-4333-8333-333333333301"), title: "Spread hummus", detail: "Coat each tortilla almost to the edge.", durationSeconds: 120),
                RecipeStep(id: StableID.make("33333333-3333-4333-8333-333333333302"), title: "Fill and roll", detail: "Layer vegetables, tuck, and slice.", durationSeconds: 240)
            ]
        ),
        Recipe(
            id: StableID.make("44444444-4444-4444-8444-444444444444"),
            title: "Chicken Noodle Mugs",
            summary: "A weeknight soup that simmers while homework starts.",
            pace: .quick,
            slot: .lunch,
            dietTags: [.nutFree, .dairyFree],
            servings: 4,
            minutes: 22,
            ingredients: [
                RecipeIngredient(id: StableID.make("44444444-4444-4444-8444-444444444201"), name: "Cooked chicken", quantity: 2, unit: "cups", category: .meats),
                RecipeIngredient(id: StableID.make("44444444-4444-4444-8444-444444444202"), name: "Egg noodles", quantity: 8, unit: "oz", category: .pantry),
                RecipeIngredient(id: StableID.make("44444444-4444-4444-8444-444444444203"), name: "Chicken broth", quantity: 6, unit: "cups", category: .pantry),
                RecipeIngredient(id: StableID.make("44444444-4444-4444-8444-444444444204"), name: "Carrots", quantity: 2, unit: "medium", category: .produce),
                RecipeIngredient(id: StableID.make("44444444-4444-4444-8444-444444444205"), name: "Celery", quantity: 2, unit: "ribs", category: .produce)
            ],
            steps: [
                RecipeStep(id: StableID.make("44444444-4444-4444-8444-444444444301"), title: "Simmer vegetables", detail: "Cook carrot and celery in broth until tender.", durationSeconds: 360),
                RecipeStep(id: StableID.make("44444444-4444-4444-8444-444444444302"), title: "Add noodles", detail: "Drop noodles and chicken, then cook until soft.", durationSeconds: 480)
            ]
        ),
        Recipe(
            id: StableID.make("55555555-5555-4555-8555-555555555555"),
            title: "Garden Pasta Bowls",
            summary: "Cherry tomatoes burst into a glossy sauce over warm pasta.",
            pace: .balanced,
            slot: .lunch,
            dietTags: [.vegetarian],
            servings: 4,
            minutes: 28,
            ingredients: [
                RecipeIngredient(id: StableID.make("55555555-5555-4555-8555-555555555201"), name: "Short pasta", quantity: 12, unit: "oz", category: .pantry),
                RecipeIngredient(id: StableID.make("55555555-5555-4555-8555-555555555202"), name: "Cherry tomatoes", quantity: 3, unit: "cups", category: .produce),
                RecipeIngredient(id: StableID.make("55555555-5555-4555-8555-555555555203"), name: "Fresh basil", quantity: 1, unit: "cup", category: .produce),
                RecipeIngredient(id: StableID.make("55555555-5555-4555-8555-555555555204"), name: "Olive oil", quantity: 3, unit: "tbsp", category: .pantry),
                RecipeIngredient(id: StableID.make("55555555-5555-4555-8555-555555555205"), name: "Parmesan", quantity: 0.5, unit: "cup", category: .dairy)
            ],
            steps: [
                RecipeStep(id: StableID.make("55555555-5555-4555-8555-555555555301"), title: "Boil pasta", detail: "Salt the water and cook until just tender.", durationSeconds: 600),
                RecipeStep(id: StableID.make("55555555-5555-4555-8555-555555555302"), title: "Warm tomatoes", detail: "Blister tomatoes in oil while pasta cooks.", durationSeconds: 360)
            ]
        ),
        Recipe(
            id: StableID.make("66666666-6666-4666-8666-666666666666"),
            title: "Sheet-Pan Salmon Supper",
            summary: "Fish, greens, and rice share the oven so plates land together.",
            pace: .balanced,
            slot: .dinner,
            dietTags: [.dairyFree, .nutFree],
            servings: 4,
            minutes: 30,
            ingredients: [
                RecipeIngredient(id: StableID.make("66666666-6666-4666-8666-666666666201"), name: "Salmon fillets", quantity: 4, unit: "pieces", category: .meats),
                RecipeIngredient(id: StableID.make("66666666-6666-4666-8666-666666666202"), name: "Broccoli florets", quantity: 4, unit: "cups", category: .produce),
                RecipeIngredient(id: StableID.make("66666666-6666-4666-8666-666666666203"), name: "Lemon", quantity: 1, unit: "whole", category: .produce),
                RecipeIngredient(id: StableID.make("66666666-6666-4666-8666-666666666204"), name: "Olive oil", quantity: 2, unit: "tbsp", category: .pantry),
                RecipeIngredient(id: StableID.make("66666666-6666-4666-8666-666666666205"), name: "White rice", quantity: 1.5, unit: "cups", category: .pantry)
            ],
            steps: [
                RecipeStep(id: StableID.make("66666666-6666-4666-8666-666666666301"), title: "Roast the tray", detail: "Bake salmon and broccoli until flaky and browned.", durationSeconds: 1080),
                RecipeStep(id: StableID.make("66666666-6666-4666-8666-666666666302"), title: "Cook the rice", detail: "Simmer rice in a covered pot.", durationSeconds: 900)
            ]
        ),
        Recipe(
            id: StableID.make("77777777-7777-4777-8777-777777777777"),
            title: "Family Taco Night",
            summary: "A build-your-own platter that feeds a crowded table.",
            pace: .family,
            slot: .dinner,
            dietTags: [.kidFriendly, .nutFree],
            servings: 6,
            minutes: 32,
            ingredients: [
                RecipeIngredient(id: StableID.make("77777777-7777-4777-8777-777777777201"), name: "Ground turkey", quantity: 1.5, unit: "lb", category: .meats),
                RecipeIngredient(id: StableID.make("77777777-7777-4777-8777-777777777202"), name: "Corn tortillas", quantity: 16, unit: "pieces", category: .pantry),
                RecipeIngredient(id: StableID.make("77777777-7777-4777-8777-777777777203"), name: "Salsa", quantity: 1.5, unit: "cups", category: .pantry),
                RecipeIngredient(id: StableID.make("77777777-7777-4777-8777-777777777204"), name: "Cheddar", quantity: 2, unit: "cups", category: .dairy),
                RecipeIngredient(id: StableID.make("77777777-7777-4777-8777-777777777205"), name: "Romaine lettuce", quantity: 1, unit: "head", category: .produce),
                RecipeIngredient(id: StableID.make("77777777-7777-4777-8777-777777777206"), name: "Tomato", quantity: 2, unit: "medium", category: .produce)
            ],
            steps: [
                RecipeStep(id: StableID.make("77777777-7777-4777-8777-777777777301"), title: "Brown the turkey", detail: "Crumble turkey in a skillet until cooked through.", durationSeconds: 480),
                RecipeStep(id: StableID.make("77777777-7777-4777-8777-777777777302"), title: "Warm tortillas", detail: "Heat tortillas in a dry pan until pliable.", durationSeconds: 180),
                RecipeStep(id: StableID.make("77777777-7777-4777-8777-777777777303"), title: "Chop toppings", detail: "Shred lettuce, dice tomato, and set out bowls.", durationSeconds: 360)
            ]
        ),
        Recipe(
            id: StableID.make("88888888-8888-4888-8888-888888888888"),
            title: "One-Pot Tomato Rice",
            summary: "A gentle simmer pot that turns pantry staples into dinner.",
            pace: .balanced,
            slot: .dinner,
            dietTags: [.vegan, .glutenFree, .dairyFree],
            servings: 5,
            minutes: 35,
            ingredients: [
                RecipeIngredient(id: StableID.make("88888888-8888-4888-8888-888888888201"), name: "Long-grain rice", quantity: 1.5, unit: "cups", category: .pantry),
                RecipeIngredient(id: StableID.make("88888888-8888-4888-8888-888888888202"), name: "Crushed tomatoes", quantity: 28, unit: "oz", category: .pantry),
                RecipeIngredient(id: StableID.make("88888888-8888-4888-8888-888888888203"), name: "Yellow onion", quantity: 1, unit: "large", category: .produce),
                RecipeIngredient(id: StableID.make("88888888-8888-4888-8888-888888888204"), name: "Garlic", quantity: 3, unit: "cloves", category: .produce),
                RecipeIngredient(id: StableID.make("88888888-8888-4888-8888-888888888205"), name: "Chickpeas", quantity: 15, unit: "oz", category: .pantry),
                RecipeIngredient(id: StableID.make("88888888-8888-4888-8888-888888888206"), name: "Baby spinach", quantity: 3, unit: "cups", category: .produce)
            ],
            steps: [
                RecipeStep(id: StableID.make("88888888-8888-4888-8888-888888888301"), title: "Soften the onion", detail: "Cook onion and garlic until sweet and pale.", durationSeconds: 300),
                RecipeStep(id: StableID.make("88888888-8888-4888-8888-888888888302"), title: "Simmer the rice", detail: "Add rice, tomatoes, and chickpeas. Cover and cook.", durationSeconds: 1080)
            ]
        )
    ]
}
