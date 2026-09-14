import StoreKit
import UIKit

enum AppLinks: String {
    case privacy = "https://brevianameal346navigator.site/privacy/458"
    case terms = "https://brevianameal346navigator.site/terms/458"

    static func rateApp() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { scene in
            scene as? UIWindowScene
        }
        let windowScene = scenes.first(where: { scene in
            scene.activationState == .foregroundActive
        }) ?? scenes.first
        if let windowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
