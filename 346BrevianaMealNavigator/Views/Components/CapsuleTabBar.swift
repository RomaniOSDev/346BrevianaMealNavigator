import SwiftUI

struct CapsuleTabBar: View {
    @Binding var selectedTab: AppTab
    var cookBadge: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 18, weight: .semibold))
                            if tab == .cook && cookBadge > 0 {
                                Text(cookBadge > 9 ? "9+" : "\(cookBadge)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Palette.onBackdrop)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Palette.primary)
                                    .clipShape(Capsule())
                                    .offset(x: 10, y: -8)
                            }
                        }
                        Text(tab.title)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(selectedTab == tab ? Palette.onBackdrop : Palette.onBackdrop.opacity(0.78))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selectedTab == tab ? Palette.primary : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Palette.surface)
        .clipShape(Capsule())
        .shadow(color: Palette.background.opacity(0.5), radius: 16, x: 0, y: 8)
        .overlay(
            Capsule()
                .stroke(Palette.primary.opacity(0.35), lineWidth: 1)
        )
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}
