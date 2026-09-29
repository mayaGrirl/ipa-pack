import Foundation

enum RemoteConfig {
    private static let lock = NSLock()
    private static var fetching = false

    static func fetchAsync() {
        guard ShellConfig.enableRemoteURL, !ShellConfig.remoteConfigURL.isEmpty else { return }
        lock.lock()
        if fetching {
            lock.unlock()
            return
        }
        fetching = true
        lock.unlock()

        Task.detached {
            await fetchInternal()
            lock.lock()
            fetching = false
            lock.unlock()
        }
    }

    static func awaitFetch(timeout: TimeInterval) {
        guard ShellConfig.enableRemoteURL, !ShellConfig.remoteConfigURL.isEmpty else { return }
        let semaphore = DispatchSemaphore(value: 0)
        Task.detached {
            await fetchInternal()
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + timeout)
    }

    static func webURL() -> String {
        if ShellConfig.enableRemoteURL {
            let cached = AppPrefs.cachedWebURL
            if isValidURL(cached), !isCacheExpired(AppPrefs.remoteConfigTime) {
                return cached
            }
        }
        return ShellConfig.webURL
    }

    private static func fetchInternal() async {
        guard let url = URL(string: ShellConfig.remoteConfigURL) else { return }
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let webURL = json?["web_url"] as? String ?? ""
            if isValidURL(webURL) {
                AppPrefs.cachedWebURL = webURL
            }
        } catch {
            NSLog("Remote config fetch failed: \(error.localizedDescription)")
        }
    }

    private static func isValidURL(_ value: String) -> Bool {
        value.hasPrefix("http://") || value.hasPrefix("https://")
    }

    private static func isCacheExpired(_ cacheTime: TimeInterval) -> Bool {
        guard cacheTime > 0 else { return true }
        let ttl = TimeInterval(ShellConfig.remoteConfigCacheHours) * 60 * 60
        return Date().timeIntervalSince1970 - cacheTime > ttl
    }
}
