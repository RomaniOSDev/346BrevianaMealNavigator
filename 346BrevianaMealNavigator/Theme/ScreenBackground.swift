import SwiftUI

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image("BgKitchen")
                            .resizable()
                            .scaledToFill()
                            .opacity(0.16)
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func kitchenBackdrop() -> some View {
        modifier(ScreenBackground())
    }
}
