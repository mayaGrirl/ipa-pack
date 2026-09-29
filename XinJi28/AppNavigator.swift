import UIKit

enum AppNavigator {
    static func launchViewController() -> UIViewController {
        if ShellConfig.showPrivacyOnFirstLaunch, !AppPrefs.isPrivacyAccepted {
            return PrivacyViewController()
        }
        return postPrivacyViewController()
    }

    static func postPrivacyViewController() -> UIViewController {
        if ShellConfig.showGuideOnFirstLaunch, !AppPrefs.isGuideShown {
            return GuideViewController()
        }
        return MainViewController()
    }
}
