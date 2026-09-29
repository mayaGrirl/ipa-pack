import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var wasInBackground = false

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = Brand.background
        window.rootViewController = SplashViewController()
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        wasInBackground = true
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        guard wasInBackground else { return }
        wasInBackground = false
        if let main = window?.rootViewController as? MainViewController {
            main.showResumeSplash()
        }
    }
}
