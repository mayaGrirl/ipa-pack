import Foundation

/// 壳包运行时配置。数值来自打包时读取的 `app-config.json`。
enum ShellConfig {
    static var webURL: String { AppConfig.webURL }

    static var userAgentSuffix: String {
        "\(AppConfig.userAgentName)/\(versionName)"
    }

    static var showGuideOnFirstLaunch: Bool { AppConfig.showGuideOnFirstLaunch }
    static var enableVideoSplash: Bool { AppConfig.enableVideoSplash }
    static var splashDuration: TimeInterval { TimeInterval(AppConfig.splashDurationMs) / 1000 }
    static var enablePullToRefresh: Bool { AppConfig.enablePullToRefresh }
    static var showPrivacyOnFirstLaunch: Bool { AppConfig.showPrivacyOnFirstLaunch }
    static var privacyPolicyURL: String { AppConfig.privacyPolicyURL }
    static var enableRemoteURL: Bool { AppConfig.enableRemoteURL }
    static var remoteConfigURL: String { AppConfig.remoteConfigURL }
    static var remoteConfigCacheHours: Int { AppConfig.remoteConfigCacheHours }
    static var appName: String { AppConfig.appName }

    static let splashTagline = "畅享精彩 尽在XJ28"

    static var versionName: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.001"
    }

    static var versionCode: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
