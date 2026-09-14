import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showResetConfirm = false
    @State private var feedback: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BannerHeader(
                        imageName: "BannerPasta",
                        title: "Kitchen Desk",
                        subtitle: "Reviews, policies, and a clean slate for this cookbook."
                    )

                    if let feedback {
                        FeedbackBanner(text: feedback)
                    }

                    CookbookCard {
                        VStack(alignment: .leading, spacing: 12) {
                            NavigationLink {
                                KitchenStatsView()
                            } label: {
                                settingsRowLabel(title: "Kitchen stats", symbol: "chart.bar.fill")
                            }
                            .buttonStyle(.plain)
                            divider
                            NavigationLink {
                                MealBoardView()
                            } label: {
                                settingsRowLabel(title: "Meal board", symbol: "calendar")
                            }
                            .buttonStyle(.plain)
                            divider
                            NavigationLink {
                                PrepAheadView()
                            } label: {
                                settingsRowLabel(title: "Prep ahead", symbol: "moon.fill")
                            }
                            .buttonStyle(.plain)
                            divider
                            NavigationLink {
                                LeftoversView()
                            } label: {
                                settingsRowLabel(title: "Leftovers", symbol: "refrigerator.fill")
                            }
                            .buttonStyle(.plain)
                            divider
                            settingsRow(title: "Rate Us", symbol: "star.fill") {
                                AppLinks.rateApp()
                                feedback = "Thanks for taking a moment to rate."
                            }
                            divider
                            settingsRow(title: "Privacy", symbol: "hand.raised.fill") {
                                if let url = URL(string: AppLinks.privacy.rawValue) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            divider
                            settingsRow(title: "Terms", symbol: "doc.text.fill") {
                                if let url = URL(string: AppLinks.terms.rawValue) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }

                    CookbookCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Danger shelf")
                                .font(.system(.title3, design: .serif).weight(.bold))
                                .foregroundColor(Palette.ink)
                            Text("Reset clears favorites, grocery list, pantry, timers, notes, stats, meal board, staples, leftovers, and preferences.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(Palette.muted)
                            GradientActionButton(title: "Reset All Data", systemImage: "trash") {
                                showResetConfirm = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .kitchenScreen()
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { recipeID in
                if let recipe = store.recipe(id: recipeID) {
                    RecipeDetailView(recipe: recipe)
                }
            }
            .alert("Reset All Data", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetAllData()
                    feedback = "All saved data was cleared."
                }
            } message: {
                Text("This removes favorites, grocery list, pantry, timers, notes, stats, meal board, staples, leftovers, and preferences.")
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.fieldFill)
            .frame(height: 1)
    }

    private func settingsRow(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            settingsRowLabel(title: title, symbol: symbol)
        }
        .buttonStyle(.plain)
    }

    private func settingsRowLabel(title: String, symbol: String) -> some View {
        HStack {
            Image(systemName: symbol)
                .foregroundColor(Palette.primary)
                .frame(width: 28)
            Text(title)
                .font(.system(.headline, design: .serif))
                .foregroundColor(Palette.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Palette.muted)
        }
        .padding(.vertical, 6)
    }
}
