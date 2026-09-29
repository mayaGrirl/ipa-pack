import UIKit

final class SplashViewController: UIViewController {
    private var navigated = false

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(SplashContentView(frame: view.bounds))
        view.subviews.last?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        RemoteConfig.fetchAsync()
        DispatchQueue.main.asyncAfter(deadline: .now() + ShellConfig.splashDuration) { [weak self] in
            self?.navigateNext()
        }
    }

    private func navigateNext() {
        guard !navigated else { return }
        navigated = true
        guard ShellConfig.enableRemoteURL else {
            transition(to: AppNavigator.launchViewController())
            return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            RemoteConfig.awaitFetch(timeout: 1.5)
            DispatchQueue.main.async {
                guard let self else { return }
                self.transition(to: AppNavigator.launchViewController())
            }
        }
    }

    private func transition(to controller: UIViewController) {
        guard let window = view.window else {
            present(controller, animated: true)
            return
        }
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = controller
        }
    }
}
