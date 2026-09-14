import SwiftUI

struct KitchenStatsView: View {
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BannerHeader(
                    imageName: "BannerTimer",
                    title: "Kitchen stats",
                    subtitle: "Cooks, market runs, and how the week is actually feeding the table."
                )

                summaryGrid

                CookbookCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cooks this week")
                            .font(.system(.title3, design: .serif).weight(.bold))
                            .foregroundColor(Palette.ink)
                        Text("How many plates you started timers for, day by day.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Palette.muted)
                        KitchenBarChart(bars: weekBars, unitLabel: "Bars count a recipe once per day.")
                    }
                }

                CookbookCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meal slots")
                            .font(.system(.title3, design: .serif).weight(.bold))
                            .foregroundColor(Palette.ink)
                        if slotSlices.contains(where: { slice in slice.value > 0 }) {
                            KitchenDonutChart(slices: slotSlices)
                        } else {
                            Text("Start a timer from a recipe and the breakfast / lunch / dinner split appears here.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(Palette.muted)
                        }
                    }
                }

                CookbookCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cook pace")
                            .font(.system(.title3, design: .serif).weight(.bold))
                            .foregroundColor(Palette.ink)
                        KitchenHBarChart(bars: paceBars)
                    }
                }

                CookbookCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Market categories")
                            .font(.system(.title3, design: .serif).weight(.bold))
                            .foregroundColor(Palette.ink)
                        Text("Items marked acquired, grouped by aisle.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Palette.muted)
                        KitchenHBarChart(bars: groceryBars)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .kitchenScreen()
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var cookedEvents: [KitchenEvent] {
        store.kitchenEvents.filter { event in event.kind == .cooked }
    }

    private var acquiredEvents: [KitchenEvent] {
        store.kitchenEvents.filter { event in event.kind == .acquired }
    }

    private var cookStreak: Int {
        let calendar = Calendar.current
        let days = Set(cookedEvents.map { event in
            calendar.startOfDay(for: event.date)
        })
        var streak = 0
        var cursor = calendar.startOfDay(for: Date())
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }
        return streak
    }

    private var cooksThisWeek: Int {
        weekBars.reduce(0) { $0 + Int($1.value) }
    }

    private var summaryGrid: some View {
        let items: [(String, String, String)] = [
            ("\(cooksThisWeek)", "Cooks / 7 days", "flame.fill"),
            ("\(cookStreak)", "Day streak", "bolt.heart.fill"),
            ("\(store.favoriteRecipes.count)", "Favorites", "heart.fill"),
            ("\(store.pantryItems.count)", "Pantry staples", "shippingbox.fill")
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(items, id: \.1) { item in
                CookbookCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: item.2)
                            .foregroundColor(Palette.primary)
                        Text(item.0)
                            .font(.system(.title, design: .serif).weight(.bold))
                            .foregroundColor(Palette.ink)
                        Text(item.1)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundColor(Palette.muted)
                    }
                }
            }
        }
    }

    private var weekBars: [ChartBar] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EE"
        return (0..<7).reversed().compactMap { offset -> ChartBar? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else {
                return nil
            }
            let start = calendar.startOfDay(for: day)
            let count = cookedEvents.filter { event in
                calendar.isDate(event.date, inSameDayAs: start)
            }.count
            return ChartBar(
                id: "day-\(offset)",
                label: formatter.string(from: start),
                value: Double(count),
                color: offset == 0 ? Palette.primary : Palette.accent
            )
        }
    }

    private var slotSlices: [ChartBar] {
        let colors = [Palette.primary, Palette.accent, Palette.background]
        return MealSlot.allCases.enumerated().map { index, slot in
            let count = cookedEvents.filter { event in event.slot == slot }.count
            return ChartBar(id: slot.rawValue, label: slot.label, value: Double(count), color: colors[index % colors.count])
        }
    }

    private var paceBars: [ChartBar] {
        let colors = [Palette.primary, Palette.accent, Palette.background]
        return MealPace.allCases.enumerated().map { index, pace in
            let count = cookedEvents.filter { event in event.pace == pace }.count
            return ChartBar(id: pace.rawValue, label: pace.label, value: Double(count), color: colors[index % colors.count])
        }
    }

    private var groceryBars: [ChartBar] {
        let colors = [Palette.primary, Palette.accent, Palette.background, Palette.surface]
        return GroceryCategory.allCases.enumerated().map { index, category in
            let count = acquiredEvents.filter { event in event.groceryCategory == category }.count
            return ChartBar(id: category.rawValue, label: category.label, value: Double(count), color: colors[index % colors.count])
        }
    }
}
