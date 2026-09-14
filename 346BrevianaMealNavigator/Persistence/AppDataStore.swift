import Combine
import Foundation
import SwiftUI
import UIKit

@MainActor
final class AppDataStore: ObservableObject {
    @Published var favoriteRecipes: [UUID] = []
    @Published var userDietaryPreferences: [DietTag] = []
    @Published var lastViewedRecipeID: UUID?
    @Published var recipeSortOrder: RecipeSortOrder = .name
    @Published var groceryList: [GroceryItem] = []
    @Published var recentRecipes: [UUID] = []
    @Published var pantryItems: [PantryItem] = []
    @Published var activeTimers: [CookTimer] = []
    @Published var lastUsedRecipeId: UUID?
    @Published var requestedTab: AppTab?
    @Published var kitchenEvents: [KitchenEvent] = []
    @Published var recipeNotes: [RecipeNote] = []
    @Published var mealBoard: [MealBoardPin] = []
    @Published var stapleRules: [StapleRule] = []
    @Published var prepTasks: [PrepTask] = []
    @Published var leftovers: [LeftoverEntry] = []
    @Published var preferredSwaps: [String: String] = [:]

    let catalog: [Recipe] = SeededCookbook.recipes

    private var tickTimer: Timer?
    private var sceneObservers: [NSObjectProtocol] = []

    private enum Keys {
        static let favoriteRecipes = "favoriteRecipes"
        static let userDietaryPreferences = "userDietaryPreferences"
        static let lastViewedRecipeID = "lastViewedRecipeID"
        static let recipeSortOrder = "recipeSortOrder"
        static let groceryList = "groceryList"
        static let recentRecipes = "recentRecipes"
        static let pantryItems = "pantryItems"
        static let activeTimers = "activeTimers"
        static let lastUsedRecipeId = "lastUsedRecipeId"
        static let kitchenEvents = "kitchenEvents"
        static let recipeNotes = "recipeNotes"
        static let mealBoard = "mealBoard"
        static let stapleRules = "stapleRules"
        static let prepTasks = "prepTasks"
        static let leftovers = "leftovers"
        static let preferredSwaps = "preferredSwaps"
    }

    init() {
        loadAll()
        startTicking()
        observeSceneActivity()
    }

    func recipe(id: UUID) -> Recipe? {
        catalog.first { item in item.id == id }
    }

    func isFavorite(_ id: UUID) -> Bool {
        favoriteRecipes.contains(id)
    }

    func toggleFavorite(_ id: UUID) {
        if let index = favoriteRecipes.firstIndex(of: id) {
            favoriteRecipes.remove(at: index)
        } else {
            favoriteRecipes.append(id)
        }
        persist(favoriteRecipes, key: Keys.favoriteRecipes)
    }

    func markRecipeViewed(_ id: UUID) {
        lastViewedRecipeID = id
        persistOptional(id, key: Keys.lastViewedRecipeID)
        recentRecipes.removeAll { item in item == id }
        recentRecipes.insert(id, at: 0)
        if recentRecipes.count > 10 {
            recentRecipes = Array(recentRecipes.prefix(10))
        }
        persist(recentRecipes, key: Keys.recentRecipes)
    }

    func markRecipeUsed(_ id: UUID) {
        lastUsedRecipeId = id
        persistOptional(id, key: Keys.lastUsedRecipeId)
    }

    func setSortOrder(_ order: RecipeSortOrder) {
        recipeSortOrder = order
        persist(order, key: Keys.recipeSortOrder)
    }

    func setDietaryPreferences(_ tags: [DietTag]) {
        userDietaryPreferences = tags
        persist(tags, key: Keys.userDietaryPreferences)
    }

    func pantryNameSet() -> Set<String> {
        Set(pantryItems.map { item in
            item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        })
    }

    func addIngredientsToList(from recipe: Recipe) -> IngredientAddResult {
        let pantry = pantryNameSet()
        var added = 0
        var skippedPantry = 0
        var merged = 0

        for ingredient in recipe.ingredients {
            let key = ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if key.isEmpty {
                continue
            }
            if pantry.contains(key) {
                skippedPantry += 1
                continue
            }
            let displayName = preferredSwaps[key] ?? ingredient.name
            let displayKey = displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if let index = groceryList.firstIndex(where: { item in
                item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == displayKey
                    && item.unit == ingredient.unit
                    && item.isAcquired == false
            }) {
                groceryList[index].quantity += ingredient.quantity
                merged += 1
            } else {
                let entry = GroceryItem(
                    id: UUID(),
                    name: displayName,
                    quantity: ingredient.quantity,
                    unit: ingredient.unit,
                    category: ingredient.category,
                    isAcquired: false,
                    sourceRecipeTitle: recipe.title
                )
                groceryList.append(entry)
                added += 1
            }
        }

        persist(groceryList, key: Keys.groceryList)
        markRecipeUsed(recipe.id)
        if added > 0 || merged > 0 {
            recordEvent(
                kind: .shopped,
                recipe: recipe
            )
        }
        return IngredientAddResult(added: added, merged: merged, skippedPantry: skippedPantry)
    }

    func toggleAcquired(_ id: UUID) {
        guard let index = groceryList.firstIndex(where: { item in item.id == id }) else { return }
        groceryList[index].isAcquired.toggle()
        persist(groceryList, key: Keys.groceryList)
        if groceryList[index].isAcquired {
            recordEvent(
                kind: .acquired,
                recipeTitle: groceryList[index].sourceRecipeTitle,
                groceryCategory: groceryList[index].category
            )
        }
    }

    func updateGroceryQuantity(id: UUID, quantity: Double, unit: String) -> Bool {
        guard quantity > 0 else { return false }
        guard let index = groceryList.firstIndex(where: { item in item.id == id }) else { return false }
        groceryList[index].quantity = quantity
        groceryList[index].unit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        persist(groceryList, key: Keys.groceryList)
        return true
    }

    func addCustomGrocery(name: String, quantity: Double, unit: String, category: GroceryCategory) -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return "Enter an item name."
        }
        if quantity <= 0 {
            return "Quantity must be greater than zero."
        }
        let entry = GroceryItem(
            id: UUID(),
            name: trimmedName,
            quantity: quantity,
            unit: trimmedUnit,
            category: category,
            isAcquired: false,
            sourceRecipeTitle: "Added by hand"
        )
        groceryList.append(entry)
        persist(groceryList, key: Keys.groceryList)
        return nil
    }

    func deleteGrocery(_ id: UUID) {
        groceryList.removeAll { item in item.id == id }
        persist(groceryList, key: Keys.groceryList)
    }

    func clearAcquiredGroceries() {
        groceryList.removeAll { item in item.isAcquired }
        persist(groceryList, key: Keys.groceryList)
    }

    func addPantryItem(name: String, category: GroceryCategory) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Enter a pantry item name."
        }
        let key = trimmed.lowercased()
        if pantryItems.contains(where: { item in
            item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key
        }) {
            return "That item is already in the pantry."
        }
        pantryItems.append(PantryItem(id: UUID(), name: trimmed, category: category))
        persist(pantryItems, key: Keys.pantryItems)
        return nil
    }

    func deletePantryItem(_ id: UUID) {
        pantryItems.removeAll { item in item.id == id }
        persist(pantryItems, key: Keys.pantryItems)
    }

    func startTimers(from recipe: Recipe) -> TimerStartResult {
        let timedSteps = recipe.steps.filter { step in step.durationSeconds > 0 }
        if timedSteps.isEmpty {
            return TimerStartResult(started: 0, skipped: 0, message: "This recipe has no timed steps.")
        }

        var started = 0
        var skipped = 0
        for step in timedSteps {
            let alreadyOpen = activeTimers.contains { timer in
                timer.recipeId == recipe.id
                    && timer.stepTitle == step.title
                    && timer.isFinished == false
            }
            if alreadyOpen {
                skipped += 1
                continue
            }
            let timer = CookTimer(
                id: UUID(),
                recipeId: recipe.id,
                recipeTitle: recipe.title,
                stepTitle: step.title,
                totalSeconds: step.durationSeconds,
                remainingSeconds: step.durationSeconds,
                isPaused: false,
                wasRunningBeforeScenePause: false
            )
            activeTimers.append(timer)
            started += 1
        }

        persist(activeTimers, key: Keys.activeTimers)
        markRecipeUsed(recipe.id)
        if started > 0 {
            recordCookedIfNeeded(recipe)
        }
        if started == 0 {
            return TimerStartResult(started: 0, skipped: skipped, message: "Those step timers are already running.")
        }
        let label = started == 1 ? "1 timer started." : "\(started) timers started."
        return TimerStartResult(started: started, skipped: skipped, message: label)
    }

    func startSingleTimer(recipe: Recipe, step: RecipeStep) -> String {
        guard step.durationSeconds > 0 else {
            return "That step has no duration."
        }
        let alreadyOpen = activeTimers.contains { timer in
            timer.recipeId == recipe.id
                && timer.stepTitle == step.title
                && timer.isFinished == false
        }
        if alreadyOpen {
            return "That step timer is already on the board."
        }
        let timer = CookTimer(
            id: UUID(),
            recipeId: recipe.id,
            recipeTitle: recipe.title,
            stepTitle: step.title,
            totalSeconds: step.durationSeconds,
            remainingSeconds: step.durationSeconds,
            isPaused: false,
            wasRunningBeforeScenePause: false
        )
        activeTimers.append(timer)
        persist(activeTimers, key: Keys.activeTimers)
        markRecipeUsed(recipe.id)
        recordCookedIfNeeded(recipe)
        return "Timer started for \(step.title)."
    }

    func toggleTimerPaused(_ id: UUID) {
        guard let index = activeTimers.firstIndex(where: { timer in timer.id == id }) else { return }
        if activeTimers[index].isFinished {
            return
        }
        activeTimers[index].isPaused.toggle()
        activeTimers[index].wasRunningBeforeScenePause = false
        persist(activeTimers, key: Keys.activeTimers)
    }

    func pauseAllRunningTimers() {
        var changed = false
        for index in activeTimers.indices {
            if activeTimers[index].isPaused == false && activeTimers[index].isFinished == false {
                activeTimers[index].isPaused = true
                changed = true
            }
        }
        if changed {
            persist(activeTimers, key: Keys.activeTimers)
        }
    }

    func resumeAllPausedTimers() {
        var changed = false
        for index in activeTimers.indices {
            if activeTimers[index].isPaused && activeTimers[index].isFinished == false {
                activeTimers[index].isPaused = false
                activeTimers[index].wasRunningBeforeScenePause = false
                changed = true
            }
        }
        if changed {
            persist(activeTimers, key: Keys.activeTimers)
        }
    }

    func deleteTimer(_ id: UUID) {
        activeTimers.removeAll { timer in timer.id == id }
        persist(activeTimers, key: Keys.activeTimers)
    }

    func clearFinishedTimers() {
        activeTimers.removeAll { timer in timer.isFinished }
        persist(activeTimers, key: Keys.activeTimers)
    }

    var runningTimerCount: Int {
        activeTimers.filter { timer in timer.isFinished == false && timer.isPaused == false }.count
    }

    func openMarket() {
        requestedTab = .market
    }

    func openCook() {
        requestedTab = .cook
    }

    func noteText(for recipeId: UUID) -> String {
        recipeNotes.first { note in note.recipeId == recipeId }?.text ?? ""
    }

    func setNote(for recipeId: UUID, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = recipeNotes.firstIndex(where: { note in note.recipeId == recipeId }) {
            if trimmed.isEmpty {
                recipeNotes.remove(at: index)
            } else {
                recipeNotes[index].text = text
            }
        } else if trimmed.isEmpty == false {
            recipeNotes.append(RecipeNote(id: UUID(), recipeId: recipeId, text: text))
        }
        persist(recipeNotes, key: Keys.recipeNotes)
    }

    func pantryCoverCount(for recipe: Recipe) -> Int {
        let pantry = pantryNameSet()
        return recipe.ingredients.filter { item in
            pantry.contains(item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        }.count
    }

    func missingIngredients(for recipe: Recipe) -> [RecipeIngredient] {
        let pantry = pantryNameSet()
        return recipe.ingredients.filter { item in
            pantry.contains(item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) == false
        }
    }

    func toggleSwap(original: String, replacement: String) {
        let key = original.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if preferredSwaps[key] == replacement {
            preferredSwaps.removeValue(forKey: key)
        } else {
            preferredSwaps[key] = replacement
        }
        persist(preferredSwaps, key: Keys.preferredSwaps)
    }

    func isSwapActive(original: String, replacement: String) -> Bool {
        let key = original.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return preferredSwaps[key] == replacement
    }

    func pinToBoard(recipeId: UUID, weekday: Int, slot: MealSlot) {
        mealBoard.removeAll { pin in pin.weekday == weekday && pin.slot == slot }
        mealBoard.append(MealBoardPin(id: UUID(), weekday: weekday, slot: slot, recipeId: recipeId))
        persist(mealBoard, key: Keys.mealBoard)
    }

    func unpinFromBoard(_ id: UUID) {
        mealBoard.removeAll { pin in pin.id == id }
        persist(mealBoard, key: Keys.mealBoard)
    }

    func boardPin(weekday: Int, slot: MealSlot) -> MealBoardPin? {
        mealBoard.first { pin in pin.weekday == weekday && pin.slot == slot }
    }

    func shopPinnedDay(_ weekday: Int) -> String {
        let pins = mealBoard.filter { pin in pin.weekday == weekday }
        if pins.isEmpty {
            return "Nothing is pinned for that day."
        }
        var added = 0
        for pin in pins {
            if let recipe = recipe(id: pin.recipeId) {
                let result = addIngredientsToList(from: recipe)
                added += result.added + result.merged
            }
        }
        if added == 0 {
            return "Those plates were already covered by pantry or the list."
        }
        return "Market updated from \(pins.count) pinned plates."
    }

    func recentlyCookedRecipes(limit: Int = 5) -> [Recipe] {
        var seen: Set<UUID> = []
        var result: [Recipe] = []
        for event in kitchenEvents.reversed() where event.kind == .cooked {
            guard let recipeId = event.recipeId, seen.contains(recipeId) == false else { continue }
            seen.insert(recipeId)
            if let recipe = recipe(id: recipeId) {
                result.append(recipe)
            }
            if result.count >= limit {
                break
            }
        }
        return result
    }

    func cookAgain(_ recipe: Recipe) -> String {
        let shop = addIngredientsToList(from: recipe)
        let timers = startTimers(from: recipe)
        if timers.started > 0 {
            openCook()
        }
        return shop.message + " " + timers.message
    }

    func addStapleRule(name: String, quantity: Double, unit: String, category: GroceryCategory, intervalDays: Int) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Enter a staple name."
        }
        if quantity <= 0 {
            return "Quantity must be greater than zero."
        }
        let days = max(1, intervalDays)
        stapleRules.append(
            StapleRule(id: UUID(), name: trimmed, quantity: quantity, unit: unit, category: category, intervalDays: days, lastAdded: Date())
        )
        persist(stapleRules, key: Keys.stapleRules)
        return nil
    }

    func deleteStapleRule(_ id: UUID) {
        stapleRules.removeAll { item in item.id == id }
        persist(stapleRules, key: Keys.stapleRules)
    }

    var dueStapleRules: [StapleRule] {
        let now = Date()
        return stapleRules.filter { rule in
            guard let last = rule.lastAdded else { return true }
            return now.timeIntervalSince(last) >= Double(rule.intervalDays) * 86400
        }
    }

    func dropDueStaples() -> String {
        let due = dueStapleRules
        if due.isEmpty {
            return "No staples are due yet."
        }
        var added = 0
        for rule in due {
            if addCustomGrocery(name: rule.name, quantity: rule.quantity, unit: rule.unit, category: rule.category) == nil {
                added += 1
                if let index = stapleRules.firstIndex(where: { item in item.id == rule.id }) {
                    stapleRules[index].lastAdded = Date()
                }
            }
        }
        persist(stapleRules, key: Keys.stapleRules)
        if added == 0 {
            return "Those staples are already on the list."
        }
        return added == 1 ? "1 staple landed on Market." : "\(added) staples landed on Market."
    }

    func buildPrepFromBoard() -> String {
        let focusDays = [BoardDay.today, BoardDay.tomorrow]
        let recipes = mealBoard.compactMap { pin -> Recipe? in
            guard focusDays.contains(pin.weekday) else { return nil }
            return recipe(id: pin.recipeId)
        }
        if recipes.isEmpty {
            return "Pin plates on the meal board first."
        }
        var created = 0
        for recipe in recipes {
            for task in PrepPlan.tasks(for: recipe) {
                let exists = prepTasks.contains { item in
                    item.recipeId == task.recipeId && item.title == task.title
                }
                if exists == false {
                    prepTasks.append(task)
                    created += 1
                }
            }
        }
        persist(prepTasks, key: Keys.prepTasks)
        if created == 0 {
            return "Prep list already matches the next two days."
        }
        return created == 1 ? "1 prep task added." : "\(created) prep tasks added."
    }

    func togglePrepTask(_ id: UUID) {
        guard let index = prepTasks.firstIndex(where: { item in item.id == id }) else { return }
        prepTasks[index].isDone.toggle()
        persist(prepTasks, key: Keys.prepTasks)
    }

    func deletePrepTask(_ id: UUID) {
        prepTasks.removeAll { item in item.id == id }
        persist(prepTasks, key: Keys.prepTasks)
    }

    func clearFinishedPrep() {
        prepTasks.removeAll { item in item.isDone }
        persist(prepTasks, key: Keys.prepTasks)
    }

    func saveLeftovers(from recipe: Recipe) -> String {
        let suggestion = leftoverSuggestion(from: recipe)
        leftovers.insert(
            LeftoverEntry(
                id: UUID(),
                name: "Leftover \(recipe.title)",
                fromRecipeTitle: recipe.title,
                suggestedRecipeId: suggestion?.id,
                suggestedRecipeTitle: suggestion?.title ?? "",
                createdAt: Date()
            ),
            at: 0
        )
        persist(leftovers, key: Keys.leftovers)
        if let suggestion {
            return "Saved leftovers. Next idea: \(suggestion.title)."
        }
        return "Saved leftovers from \(recipe.title)."
    }

    func deleteLeftover(_ id: UUID) {
        leftovers.removeAll { item in item.id == id }
        persist(leftovers, key: Keys.leftovers)
    }

    func leftoverSuggestion(from recipe: Recipe) -> Recipe? {
        let sourceNames = Set(recipe.ingredients.map { item in item.name.lowercased() })
        return catalog
            .filter { item in item.id != recipe.id }
            .max { lhs, rhs in
                overlap(lhs, sourceNames) < overlap(rhs, sourceNames)
            }
    }

    private func overlap(_ recipe: Recipe, _ names: Set<String>) -> Int {
        recipe.ingredients.filter { item in names.contains(item.name.lowercased()) }.count
    }

    func advanceHandsFreeStep() -> String {
        guard let recipe = handsFreeRecipe() else {
            return "Start a recipe timer first, then this button walks the steps."
        }
        if let index = activeTimers.firstIndex(where: { timer in
            timer.recipeId == recipe.id && timer.isFinished == false
        }) {
            let finishedTitle = activeTimers[index].stepTitle
            activeTimers[index].remainingSeconds = 0
            activeTimers[index].isPaused = true
            persist(activeTimers, key: Keys.activeTimers)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if let next = nextUnstartedStep(for: recipe) {
                let message = startSingleTimer(recipe: recipe, step: next)
                return "Done: \(finishedTitle). \(message)"
            }
            return "Done: \(finishedTitle). That plate is finished."
        }
        if let first = recipe.steps.first(where: { step in step.durationSeconds > 0 }) {
            openCook()
            return startSingleTimer(recipe: recipe, step: first)
        }
        return "That recipe has no timed steps."
    }

    func handsFreeRecipe() -> Recipe? {
        if let last = lastUsedRecipeId, let recipe = recipe(id: last) {
            return recipe
        }
        if let timer = activeTimers.first, let recipe = recipe(id: timer.recipeId) {
            return recipe
        }
        return nil
    }

    func currentHandsFreeStepTitle() -> String {
        guard let recipe = handsFreeRecipe() else {
            return "No plate on the board"
        }
        if let open = activeTimers.first(where: { timer in
            timer.recipeId == recipe.id && timer.isFinished == false
        }) {
            return open.stepTitle
        }
        if let next = nextUnstartedStep(for: recipe) {
            return next.title
        }
        return "All steps done"
    }

    private func nextUnstartedStep(for recipe: Recipe) -> RecipeStep? {
        recipe.steps.first { step in
            guard step.durationSeconds > 0 else { return false }
            return activeTimers.contains { timer in
                timer.recipeId == recipe.id && timer.stepTitle == step.title
            } == false
        }
    }

    func resetAllData() {
        let keys = [
            Keys.favoriteRecipes,
            Keys.userDietaryPreferences,
            Keys.lastViewedRecipeID,
            Keys.recipeSortOrder,
            Keys.groceryList,
            Keys.recentRecipes,
            Keys.pantryItems,
            Keys.activeTimers,
            Keys.lastUsedRecipeId,
            Keys.kitchenEvents,
            Keys.recipeNotes,
            Keys.mealBoard,
            Keys.stapleRules,
            Keys.prepTasks,
            Keys.leftovers,
            Keys.preferredSwaps
        ]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        favoriteRecipes = []
        userDietaryPreferences = []
        lastViewedRecipeID = nil
        recipeSortOrder = .name
        groceryList = []
        recentRecipes = []
        pantryItems = []
        activeTimers = []
        lastUsedRecipeId = nil
        kitchenEvents = []
        recipeNotes = []
        mealBoard = []
        stapleRules = StapleRule.starter
        prepTasks = []
        leftovers = []
        preferredSwaps = [:]
        requestedTab = .recipes
        NotificationCenter.default.post(name: Notification.Name("dataReset"), object: nil)
    }

    private func recordCookedIfNeeded(_ recipe: Recipe) {
        let calendar = Calendar.current
        let alreadyToday = kitchenEvents.contains { event in
            event.kind == .cooked
                && event.recipeId == recipe.id
                && calendar.isDate(event.date, inSameDayAs: Date())
        }
        if alreadyToday {
            return
        }
        recordEvent(kind: .cooked, recipe: recipe)
    }

    private func recordEvent(
        kind: KitchenEventKind,
        recipe: Recipe? = nil,
        recipeTitle: String? = nil,
        groceryCategory: GroceryCategory? = nil
    ) {
        let event = KitchenEvent(
            id: UUID(),
            date: Date(),
            kind: kind,
            recipeId: recipe?.id,
            recipeTitle: recipe?.title ?? recipeTitle ?? "",
            slot: recipe?.slot,
            pace: recipe?.pace,
            groceryCategory: groceryCategory
        )
        kitchenEvents.append(event)
        if kitchenEvents.count > 400 {
            kitchenEvents = Array(kitchenEvents.suffix(400))
        }
        persist(kitchenEvents, key: Keys.kitchenEvents)
    }

    private func tickActiveTimers() {
        var changed = false
        for index in activeTimers.indices {
            if activeTimers[index].isPaused == false && activeTimers[index].remainingSeconds > 0 {
                activeTimers[index].remainingSeconds -= 1
                changed = true
                if activeTimers[index].remainingSeconds == 0 {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
        if changed {
            persist(activeTimers, key: Keys.activeTimers)
        }
    }

    private func startTicking() {
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickActiveTimers()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
    }

    private func observeSceneActivity() {
        let resign = NotificationCenter.default.addObserver(
            forName: UIScene.willDeactivateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSceneInactive()
            }
        }
        let activate = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSceneActive()
            }
        }
        sceneObservers = [resign, activate]
    }

    private func handleSceneInactive() {
        var changed = false
        for index in activeTimers.indices {
            if activeTimers[index].isPaused == false && activeTimers[index].isFinished == false {
                activeTimers[index].wasRunningBeforeScenePause = true
                activeTimers[index].isPaused = true
                changed = true
            }
        }
        if changed {
            persist(activeTimers, key: Keys.activeTimers)
        }
    }

    private func handleSceneActive() {
        var changed = false
        for index in activeTimers.indices {
            if activeTimers[index].wasRunningBeforeScenePause && activeTimers[index].isFinished == false {
                activeTimers[index].isPaused = false
                activeTimers[index].wasRunningBeforeScenePause = false
                changed = true
            }
        }
        if changed {
            persist(activeTimers, key: Keys.activeTimers)
        }
    }

    private func loadAll() {
        favoriteRecipes = decode([UUID].self, key: Keys.favoriteRecipes, fallback: [])
        userDietaryPreferences = decode([DietTag].self, key: Keys.userDietaryPreferences, fallback: [])
        lastViewedRecipeID = decode(UUID?.self, key: Keys.lastViewedRecipeID, fallback: nil)
        recipeSortOrder = decode(RecipeSortOrder.self, key: Keys.recipeSortOrder, fallback: .name)
        groceryList = decode([GroceryItem].self, key: Keys.groceryList, fallback: [])
        recentRecipes = decode([UUID].self, key: Keys.recentRecipes, fallback: [])
        pantryItems = decode([PantryItem].self, key: Keys.pantryItems, fallback: [])
        activeTimers = decode([CookTimer].self, key: Keys.activeTimers, fallback: [])
        lastUsedRecipeId = decode(UUID?.self, key: Keys.lastUsedRecipeId, fallback: nil)
        kitchenEvents = decode([KitchenEvent].self, key: Keys.kitchenEvents, fallback: [])
        recipeNotes = decode([RecipeNote].self, key: Keys.recipeNotes, fallback: [])
        mealBoard = decode([MealBoardPin].self, key: Keys.mealBoard, fallback: [])
        stapleRules = decode([StapleRule].self, key: Keys.stapleRules, fallback: StapleRule.starter)
        prepTasks = decode([PrepTask].self, key: Keys.prepTasks, fallback: [])
        leftovers = decode([LeftoverEntry].self, key: Keys.leftovers, fallback: [])
        preferredSwaps = decode([String: String].self, key: Keys.preferredSwaps, fallback: [:])
        if UserDefaults.standard.data(forKey: Keys.stapleRules) == nil {
            persist(stapleRules, key: Keys.stapleRules)
        }
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func persistOptional(_ value: UUID?, key: String) {
        if let value {
            persist(value, key: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String, fallback: T) -> T {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return fallback
        }
        if let value = try? JSONDecoder().decode(type, from: data) {
            return value
        }
        return fallback
    }
}

struct IngredientAddResult {
    let added: Int
    let merged: Int
    let skippedPantry: Int

    var message: String {
        if added == 0 && merged == 0 {
            if skippedPantry > 0 {
                return "Every ingredient is already in the pantry."
            }
            return "Nothing new to add."
        }
        var parts: [String] = []
        if added > 0 {
            parts.append(added == 1 ? "1 new item" : "\(added) new items")
        }
        if merged > 0 {
            parts.append(merged == 1 ? "1 quantity updated" : "\(merged) quantities updated")
        }
        var text = parts.joined(separator: ", ") + " on the Market list."
        if skippedPantry > 0 {
            text += " Skipped \(skippedPantry) already in the pantry."
        }
        return text
    }
}

struct TimerStartResult {
    let started: Int
    let skipped: Int
    let message: String
}
