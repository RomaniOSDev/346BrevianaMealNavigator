import SwiftUI
import UIKit

enum Keyboard {
    static func hide() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

final class KeyboardTapWatcher: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardTapWatcher()
    private var installed = false

    func install() {
        guard installed == false else { return }
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first else {
            return
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        tap.name = "kitchen-dismiss-keyboard"
        window.addGestureRecognizer(tap)
        installed = true
    }

    @objc private func handleTap() {
        Keyboard.hide()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

struct KeyboardAwareModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        Keyboard.hide()
                    }
                    .foregroundColor(Palette.primary)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                }
            }
            .onAppear {
                KeyboardTapWatcher.shared.install()
            }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(KeyboardAwareModifier())
    }

    func kitchenScreen() -> some View {
        kitchenBackdrop()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .scrollDismissesKeyboard(.immediately)
    }
}
