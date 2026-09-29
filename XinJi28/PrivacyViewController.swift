import UIKit
import WebKit

final class PrivacyViewController: UIViewController {
    private let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isOpaque = false
        view.backgroundColor = Brand.background
        view.scrollView.backgroundColor = Brand.background
        return view
    }()

    private let agreeBox = UIButton(type: .system)
    private let agreeButton = UIButton(type: .system)
    private var agreed = false

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Brand.background

        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.backgroundColor = Brand.background

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "用户协议与隐私政策"
        title.font = .systemFont(ofSize: 20, weight: .bold)
        title.textColor = Brand.primary
        title.textAlignment = .center

        let footer = UIView()
        footer.translatesAutoresizingMaskIntoConstraints = false
        footer.backgroundColor = Brand.surface

        agreeBox.translatesAutoresizingMaskIntoConstraints = false
        agreeBox.setImage(UIImage(systemName: "square"), for: .normal)
        agreeBox.tintColor = Brand.primary
        agreeBox.addTarget(self, action: #selector(toggleAgree), for: .touchUpInside)
        agreeBox.setContentHuggingPriority(.required, for: .horizontal)

        let agreeLabel = UILabel()
        agreeLabel.translatesAutoresizingMaskIntoConstraints = false
        agreeLabel.text = "我已阅读并同意《用户协议》和《隐私政策》"
        agreeLabel.textColor = Brand.textPrimary
        agreeLabel.font = .systemFont(ofSize: 14)
        agreeLabel.numberOfLines = 0
        agreeLabel.isUserInteractionEnabled = true
        agreeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleAgree)))

        let agreeRow = UIStackView(arrangedSubviews: [agreeBox, agreeLabel])
        agreeRow.translatesAutoresizingMaskIntoConstraints = false
        agreeRow.axis = .horizontal
        agreeRow.alignment = .center
        agreeRow.spacing = 8

        agreeButton.translatesAutoresizingMaskIntoConstraints = false
        agreeButton.setTitle("同意并继续", for: .normal)
        agreeButton.setTitleColor(Brand.primaryDark, for: .normal)
        agreeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        agreeButton.backgroundColor = Brand.accent
        agreeButton.layer.cornerRadius = 24
        agreeButton.alpha = 0.4
        agreeButton.isEnabled = false
        agreeButton.addTarget(self, action: #selector(agree), for: .touchUpInside)

        let disagree = UIButton(type: .system)
        disagree.translatesAutoresizingMaskIntoConstraints = false
        disagree.setTitle("不同意并退出", for: .normal)
        disagree.setTitleColor(Brand.textSecondary, for: .normal)
        disagree.addTarget(self, action: #selector(disagree), for: .touchUpInside)

        header.addSubview(title)
        footer.addSubview(agreeRow)
        footer.addSubview(agreeButton)
        footer.addSubview(disagree)
        view.addSubview(header)
        view.addSubview(webView)
        view.addSubview(footer)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            title.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            title.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            title.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            title.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -16),
            webView.topAnchor.constraint(equalTo: header.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: footer.topAnchor),
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            agreeRow.topAnchor.constraint(equalTo: footer.topAnchor, constant: 20),
            agreeRow.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            agreeRow.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            agreeBox.widthAnchor.constraint(equalToConstant: 28),
            agreeBox.heightAnchor.constraint(equalToConstant: 28),
            agreeButton.topAnchor.constraint(equalTo: agreeRow.bottomAnchor, constant: 12),
            agreeButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            agreeButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            agreeButton.heightAnchor.constraint(equalToConstant: 48),
            disagree.topAnchor.constraint(equalTo: agreeButton.bottomAnchor, constant: 4),
            disagree.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            disagree.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            disagree.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -8)
        ])

        loadPrivacy()
    }

    private func loadPrivacy() {
        let remote = ShellConfig.privacyPolicyURL
        if remote.hasPrefix("http://") || remote.hasPrefix("https://"), let url = URL(string: remote) {
            webView.load(URLRequest(url: url))
            return
        }
        if let file = Bundle.main.url(forResource: "privacy_policy", withExtension: "html") {
            webView.loadFileURL(file, allowingReadAccessTo: file.deletingLastPathComponent())
        }
    }

    @objc private func toggleAgree() {
        agreed.toggle()
        let name = agreed ? "checkmark.square.fill" : "square"
        agreeBox.setImage(UIImage(systemName: name), for: .normal)
        agreeButton.isEnabled = agreed
        agreeButton.alpha = agreed ? 1 : 0.4
    }

    @objc private func agree() {
        AppPrefs.isPrivacyAccepted = true
        let next = AppNavigator.postPrivacyViewController()
        guard let window = view.window else { return }
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = next
        }
    }

    @objc private func disagree() {
        exit(0)
    }
}
