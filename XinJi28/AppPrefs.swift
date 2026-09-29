import Foundation

enum AppPrefs {
    private static let guideShownKey = "guide_shown"
    private static let privacyAcceptedKey = "privacy_accepted"
    private static let cachedWebURLKey = "cached_web_url"
    private static let remoteConfigTimeKey = "remote_config_time"

    private static var defaults: UserDefaults { .standard }

    static var isGuideShown: Bool {
        get { defaults.bool(forKey: guideShownKey) }
        set { defaults.set(newValue, forKey: guideShownKey) }
    }

    static var isPrivacyAccepted: Bool {
        get { defaults.bool(forKey: privacyAcceptedKey) }
        set { defaults.set(newValue, forKey: privacyAcceptedKey) }
    }

    static var cachedWebURL: String {
        get { defaults.string(forKey: cachedWebURLKey) ?? "" }
        set {
            defaults.set(newValue, forKey: cachedWebURLKey)
            defaults.set(Date().timeIntervalSince1970, forKey: remoteConfigTimeKey)
        }
    }

    static var remoteConfigTime: TimeInterval {
        defaults.double(forKey: remoteConfigTimeKey)
    }
}
