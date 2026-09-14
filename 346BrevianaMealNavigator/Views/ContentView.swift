import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore()
    @State private var selectedTab: AppTab = .recipes

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RecipesHomeView()
                    .opacity(selectedTab == .recipes ? 1 : 0)
                    .allowsHitTesting(selectedTab == .recipes)
                GroceryListView()
                    .opacity(selectedTab == .market ? 1 : 0)
                    .allowsHitTesting(selectedTab == .market)
                CookTimersView()
                    .opacity(selectedTab == .cook ? 1 : 0)
                    .allowsHitTesting(selectedTab == .cook)
                SettingsView()
                    .opacity(selectedTab == .more ? 1 : 0)
                    .allowsHitTesting(selectedTab == .more)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        CapsuleTabBar(selectedTab: $selectedTab, cookBadge: store.runningTimerCount)
        }
        .kitchenBackdrop()
        .environmentObject(store)
        .dismissKeyboardOnTap()
        .onChange(of: store.requestedTab) { newTab in
            if let newTab {
                selectedTab = newTab
                store.requestedTab = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            selectedTab = .recipes
        }
    }
}
