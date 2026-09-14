import SwiftUI

struct PrepAheadView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var feedback: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BannerHeader(
                    imageName: "BannerTimer",
                    title: "Prep ahead",
                    subtitle: "Tonight's thaw, chop, and rinse list from the next two days on the board."
                )

                if let feedback {
                    FeedbackBanner(text: feedback)
                }

                GradientActionButton(title: "Build from meal board", systemImage: "list.bullet.clipboard") {
                    feedback = store.buildPrepFromBoard()
                }

                if store.prepTasks.contains(where: { item in item.isDone }) {
                    SoftActionButton(title: "Clear finished", systemImage: "checkmark") {
                        store.clearFinishedPrep()
                    }
                }

                if store.prepTasks.isEmpty {
                    EmptyStateView(
                        symbol: "moon.fill",
                        title: "No prep yet",
                        message: "Pin tomorrow's plates, then build the evening checklist."
                    )
                } else {
                    ForEach(store.prepTasks) { task in
                        CookbookCard {
                            HStack(alignment: .top, spacing: 12) {
                                Button {
                                    store.togglePrepTask(task.id)
                                } label: {
                                    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(Palette.primary)
                                }
                                .buttonStyle(.plain)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(.system(.headline, design: .serif))
                                        .foregroundColor(Palette.ink)
                                        .strikethrough(task.isDone)
                                    Text(task.detail)
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(Palette.muted)
                                    Text(task.recipeTitle)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(Palette.muted)
                                }
                                Spacer(minLength: 0)
                                Button {
                                    store.deletePrepTask(task.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(Palette.primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .kitchenScreen()
        .navigationTitle("Prep ahead")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
