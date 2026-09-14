import SwiftUI

struct CookTimersView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var pendingDelete: CookTimer?
    @State private var showClearFinished = false
    @State private var feedback: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BannerHeader(
                        imageName: "BannerTimer",
                        title: "Cook board",
                        subtitle: "Parallel step timers from the recipe card you just opened."
                    )

                    if let feedback {
                        FeedbackBanner(text: feedback)
                    }

                    CookbookCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Hands-free next step")
                                .font(.system(.title3, design: .serif).weight(.bold))
                                .foregroundColor(Palette.ink)
                            Text(store.currentHandsFreeStepTitle())
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(Palette.muted)
                            Button {
                                feedback = store.advanceHandsFreeStep()
                            } label: {
                                Text("Next step")
                                    .font(.system(.title2, design: .serif).weight(.bold))
                                    .foregroundColor(Color.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 22)
                                    .background(
                                        LinearGradient(
                                            colors: [Palette.primary, Palette.accent],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if store.activeTimers.isEmpty == false {
                        HStack(spacing: 8) {
                            SoftActionButton(title: "Pause all", systemImage: "pause.fill") {
                                store.pauseAllRunningTimers()
                                feedback = "Every running timer is paused."
                            }
                            SoftActionButton(title: "Resume all", systemImage: "play.fill") {
                                store.resumeAllPausedTimers()
                                feedback = "Paused timers are running again."
                            }
                        }
                        if store.activeTimers.contains(where: { timer in timer.isFinished }) {
                            SoftActionButton(title: "Clear finished", systemImage: "checkmark.circle") {
                                showClearFinished = true
                            }
                        }
                    }

                    if store.activeTimers.isEmpty {
                        EmptyStateView(
                            symbol: "timer",
                            title: "No timers on the board",
                            message: "Open a recipe and start timers from its cook steps. They pause if you leave the scene.",
                            actionTitle: "Browse recipes"
                        ) {
                            store.requestedTab = .recipes
                        }
                    } else {
                        ForEach(store.activeTimers) { timer in
                            timerCard(timer)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .kitchenScreen()
            .navigationTitle("Cook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Remove this timer?", isPresented: deleteAlertBinding) {
                Button("Cancel", role: .cancel) {
                    pendingDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let pendingDelete {
                        store.deleteTimer(pendingDelete.id)
                        feedback = "Removed \(pendingDelete.stepTitle)."
                    }
                    pendingDelete = nil
                }
            } message: {
                Text("The remaining time will be discarded.")
            }
            .alert("Clear finished timers?", isPresented: $showClearFinished) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    store.clearFinishedTimers()
                    feedback = "Finished timers were cleared."
                }
            } message: {
                Text("Only completed timers will leave the board.")
            }
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { isPresented in
                if isPresented == false {
                    pendingDelete = nil
                }
            }
        )
    }

    private func timerCard(_ timer: CookTimer) -> some View {
        CookbookCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(timer.recipeTitle)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(Palette.muted)
                Text(timer.stepTitle)
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundColor(Palette.ink)
                Text(timer.isFinished ? "Done" : KitchenFormat.clock(timer.remainingSeconds))
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundColor(Palette.ink)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Palette.fieldFill)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Palette.primary, Palette.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * timer.progress)
                    }
                }
                .frame(height: 12)

                HStack(spacing: 8) {
                    if timer.isFinished == false {
                        SoftActionButton(
                            title: timer.isPaused ? "Resume" : "Pause",
                            systemImage: timer.isPaused ? "play.fill" : "pause.fill"
                        ) {
                            store.toggleTimerPaused(timer.id)
                        }
                    }
                    SoftActionButton(title: "Remove", systemImage: "trash") {
                        pendingDelete = timer
                    }
                }
            }
        }
    }
}
