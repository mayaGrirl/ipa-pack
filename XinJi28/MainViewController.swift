import AVFoundation
import CoreLocation
import UIKit
import WebKit

final class MainViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, CLLocationManagerDelegate {
    private let webView: WKWebView
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let loadingView = UIView()
    private let loadingLabel = UILabel()
    private let errorView = UIView()
    private let resumeSplash = SplashContentView()
    private let locationManager = CLLocationManager()
    private var progressObservation: NSKeyValueObservation?
    private var isPullRefreshing = false
    private var refreshControl: UIRefreshControl?

    init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.applicationNameForUserAgent = ShellConfig.userAgentSuffix
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Brand.background
        setupWebView()
        setupLoading()
        setupError()
        setupResumeSplash()
        requestDevicePermissions()
        loadPage()
    }

    func showResumeSplash() {
        resumeSplash.alpha = 1
        resumeSplash.isHidden = false
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideResumeSplash), object: nil)
        perform(#selector(hideResumeSplash), with: nil, afterDelay: ShellConfig.splashDuration)
    }

    @objc private func hideResumeSplash() {
        UIView.animate(withDuration: 0.3, animations: {
            self.resumeSplash.alpha = 0
        }, completion: { _ in
            self.resumeSplash.isHidden = true
        })
    }

    private func setupWebView() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = Brand.background
        webView.scrollView.backgroundColor = Brand.background
        view.addSubview(webView)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = Brand.accent
        progressView.trackTintColor = Brand.surface

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: guide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if ShellConfig.enablePullToRefresh {
            let refresh = UIRefreshControl()
            refresh.tintColor = Brand.accent
            refresh.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
            webView.scrollView.refreshControl = refresh
            refreshControl = refresh
        }

        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            guard let self else { return }
            let value = Float(webView.estimatedProgress)
            self.progressView.setProgress(value, animated: true)
            self.loadingLabel.text = "页面加载中… \(Int(value * 100))%"
        }
    }

    private func setupLoading() {
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.backgroundColor = Brand.background
        let logo = UIImageView(image: UIImage(named: "AppLogo"))
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.contentMode = .scaleAspectFit
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.text = "页面加载中…"
        loadingLabel.textColor = Brand.textSecondary
        loadingLabel.font = .systemFont(ofSize: 14)
        loadingView.addSubview(logo)
        loadingView.addSubview(progressView)
        loadingView.addSubview(loadingLabel)
        view.addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            logo.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor, constant: -36),
            logo.widthAnchor.constraint(equalToConstant: 80),
            logo.heightAnchor.constraint(equalToConstant: 80),
            progressView.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 32),
            progressView.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 200),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            loadingLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor)
        ])
    }

    private func setupError() {
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.backgroundColor = Brand.background
        errorView.isHidden = true

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = Brand.surface
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = Brand.accent.cgColor

        let mark = UILabel()
        mark.translatesAutoresizingMaskIntoConstraints = false
        mark.text = "⚠"
        mark.textColor = Brand.error
        mark.font = .systemFont(ofSize: 48)

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "网络连接失败"
        title.textColor = Brand.textPrimary
        title.font = .systemFont(ofSize: 18, weight: .bold)

        let detail = UILabel()
        detail.translatesAutoresizingMaskIntoConstraints = false
        detail.text = "请检查网络设置后重试"
        detail.textColor = Brand.textSecondary
        detail.font = .systemFont(ofSize: 14)
        detail.textAlignment = .center

        let retry = UIButton(type: .system)
        retry.translatesAutoresizingMaskIntoConstraints = false
        retry.setTitle("重新加载", for: .normal)
        retry.setTitleColor(Brand.primaryDark, for: .normal)
        retry.backgroundColor = Brand.accent
        retry.layer.cornerRadius = 24
        retry.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        retry.addTarget(self, action: #selector(loadPage), for: .touchUpInside)

        card.addSubview(mark)
        card.addSubview(title)
        card.addSubview(detail)
        card.addSubview(retry)
        errorView.addSubview(card)
        view.addSubview(errorView)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: view.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            card.centerYAnchor.constraint(equalTo: errorView.centerYAnchor),
            card.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 32),
            card.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -32),
            mark.topAnchor.constraint(equalTo: card.topAnchor, constant: 32),
            mark.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            title.topAnchor.constraint(equalTo: mark.bottomAnchor, constant: 16),
            title.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            detail.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            detail.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            detail.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            retry.topAnchor.constraint(equalTo: detail.bottomAnchor, constant: 24),
            retry.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 32),
            retry.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -32),
            retry.heightAnchor.constraint(equalToConstant: 48),
            retry.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -32)
        ])
    }

    private func setupResumeSplash() {
        resumeSplash.translatesAutoresizingMaskIntoConstraints = false
        resumeSplash.isHidden = true
        view.addSubview(resumeSplash)
        NSLayoutConstraint.activate([
            resumeSplash.topAnchor.constraint(equalTo: view.topAnchor),
            resumeSplash.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resumeSplash.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resumeSplash.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func requestDevicePermissions() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        AVCaptureDevice.requestAccess(for: .video) { _ in }
        AVCaptureDevice.requestAccess(for: .audio) { _ in }
    }

    @objc private func loadPage() {
        guard let url = URL(string: RemoteConfig.webURL()) else { return }
        showLoading()
        webView.load(URLRequest(url: url))
    }

    @objc private func pullToRefresh() {
        isPullRefreshing = true
        webView.reload()
    }

    private func showLoading() {
        if isPullRefreshing { return }
        loadingView.isHidden = false
        errorView.isHidden = true
        progressView.progress = 0
        progressView.isHidden = false
    }

    private func showContent() {
        loadingView.isHidden = true
        errorView.isHidden = true
        refreshControl?.endRefreshing()
        isPullRefreshing = false
    }

    private func showError() {
        loadingView.isHidden = true
        errorView.isHidden = false
        refreshControl?.endRefreshing()
        isPullRefreshing = false
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        showLoading()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showContent()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if isIgnorableNavigationError(error) { return }
        showError()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if isIgnorableNavigationError(error) { return }
        showError()
    }

    private func isIgnorableNavigationError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled { return true }
        // 交给系统打开的非网页链接会被策略取消，WebKit 用 102 表示这次跳转被中断。
        return nsError.domain == "WebKitErrorDomain" && nsError.code == 102
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        let scheme = url.scheme?.lowercased() ?? ""
        if scheme == "http" || scheme == "https" || scheme == "about" || scheme == "blob" {
            decisionHandler(.allow)
            return
        }
        decisionHandler(.cancel)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
            return
        }
        decisionHandler(.cancel)
        if let url = navigationResponse.response.url {
            UIApplication.shared.open(url)
        }
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    @available(iOS 15.0, *)
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.grant)
    }

    deinit {
        progressObservation?.invalidate()
    }
}
