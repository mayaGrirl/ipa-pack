import UIKit

/// 启动页和从后台回到前台时共用的过渡页：全屏启动图，底部加载。
final class SplashContentView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Brand.background

        let image = UIImageView(image: UIImage(named: "SplashBackground"))
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = Brand.primary
        spinner.startAnimating()

        let loading = UILabel()
        loading.text = "正在加载…"
        loading.font = .systemFont(ofSize: 12)
        loading.textColor = Brand.textSecondary
        loading.textAlignment = .center

        let bottomStack = UIStackView(arrangedSubviews: [spinner, loading])
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        bottomStack.axis = .vertical
        bottomStack.alignment = .center
        bottomStack.spacing = 12

        addSubview(image)
        addSubview(bottomStack)

        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: topAnchor),
            image.leadingAnchor.constraint(equalTo: leadingAnchor),
            image.trailingAnchor.constraint(equalTo: trailingAnchor),
            image.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -48)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }
}
