import AVFoundation
import AVKit
import UIKit

final class GuideViewController: UIViewController, UIScrollViewDelegate {
    private struct Slide {
        let symbol: String
        let title: String
        let detail: String
        let imageName: String
    }

    private let slides: [Slide] = [
        Slide(symbol: "lock.shield.fill", title: "安全极速", detail: "银行级加密防护，毫秒级响应，随时随地畅玩无忧", imageName: "guide_slide_1"),
        Slide(symbol: "gamecontroller.fill", title: "精彩游戏", detail: "海量热门游戏，真人娱乐，体育竞技，应有尽有", imageName: "guide_slide_2"),
        Slide(symbol: "gift.fill", title: "尊享福利", detail: "新人礼包、每日签到、VIP 专属礼遇等你来领", imageName: "guide_slide_3")
    ]

    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()
    private let actionButton = UIButton(type: .system)
    private var pageCount = 3
    private var hasVideoPage = false
    private var player: AVPlayer?
    private var loopObserver: NSObjectProtocol?

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Brand.background
        hasVideoPage = ShellConfig.enableVideoSplash && Bundle.main.url(forResource: "splash_video", withExtension: "mp4") != nil
        pageCount = hasVideoPage ? slides.count + 1 : slides.count

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.bounces = false

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = pageCount
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = Brand.accent
        pageControl.pageIndicatorTintColor = Brand.surface

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.setTitle("下一步", for: .normal)
        actionButton.setTitleColor(Brand.primaryDark, for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        actionButton.backgroundColor = Brand.accent
        actionButton.layer.cornerRadius = 24
        actionButton.addTarget(self, action: #selector(advance), for: .touchUpInside)

        let skip = UIButton(type: .system)
        skip.translatesAutoresizingMaskIntoConstraints = false
        skip.setTitle("跳过", for: .normal)
        skip.setTitleColor(Brand.textSecondary, for: .normal)
        skip.titleLabel?.font = .systemFont(ofSize: 14)
        skip.addTarget(self, action: #selector(finishGuide), for: .touchUpInside)

        view.addSubview(scrollView)
        view.addSubview(pageControl)
        view.addSubview(actionButton)
        view.addSubview(skip)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            skip.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            skip.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),
            actionButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 32),
            actionButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -32),
            actionButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -16),
            actionButton.heightAnchor.constraint(equalToConstant: 52),
            pageControl.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -24),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutPagesIfNeeded()
    }

    private var laidOutWidth: CGFloat = 0
    private let pageTag = 900

    private func layoutPagesIfNeeded() {
        let width = scrollView.bounds.width
        let height = scrollView.bounds.height
        guard width > 0, height > 0, abs(width - laidOutWidth) > 0.5 else { return }
        laidOutWidth = width
        stopVideo()
        scrollView.subviews.filter { $0.tag == pageTag }.forEach { $0.removeFromSuperview() }
        scrollView.contentSize = CGSize(width: width * CGFloat(pageCount), height: height)

        var index = 0
        if hasVideoPage {
            let page = makeVideoPage(frame: CGRect(x: 0, y: 0, width: width, height: height))
            page.tag = pageTag
            scrollView.addSubview(page)
            index = 1
        }
        for slide in slides {
            let frame = CGRect(x: width * CGFloat(index), y: 0, width: width, height: height)
            let page = makeSlide(slide, frame: frame)
            page.tag = pageTag
            scrollView.addSubview(page)
            index += 1
        }
        let page = min(pageControl.currentPage, pageCount - 1)
        scrollView.contentOffset = CGPoint(x: width * CGFloat(page), y: 0)
        updateActionTitle()
    }

    private func makeVideoPage(frame: CGRect) -> UIView {
        let container = UIView(frame: frame)
        guard let url = Bundle.main.url(forResource: "splash_video", withExtension: "mp4") else {
            return container
        }
        let player = AVPlayer(url: url)
        player.isMuted = true
        self.player = player
        let layer = AVPlayerLayer(player: player)
        layer.frame = container.bounds
        layer.videoGravity = .resizeAspectFill
        container.layer.addSublayer(layer)
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
        player.play()

        let caption = UILabel(frame: CGRect(x: 24, y: frame.height - 88, width: frame.width - 48, height: 56))
        caption.text = "欢迎加入XJ28\n开启您的精彩之旅"
        caption.numberOfLines = 2
        caption.textAlignment = .center
        caption.textColor = .white
        caption.font = .systemFont(ofSize: 18, weight: .semibold)
        container.addSubview(caption)
        return container
    }

    private func makeSlide(_ slide: Slide, frame: CGRect) -> UIView {
        let container = UIView(frame: frame)
        let imageSide = min(280, frame.width - 64)
        let top = max(80, (frame.height - 160 - imageSide - 136) / 2)
        let image = UIImageView(frame: CGRect(x: (frame.width - imageSide) / 2, y: top, width: imageSide, height: imageSide))
        image.contentMode = .scaleAspectFit
        image.tintColor = Brand.accent
        if let custom = UIImage(named: slide.imageName) {
            image.image = custom
        } else {
            let config = UIImage.SymbolConfiguration(pointSize: 72, weight: .regular)
            image.image = UIImage(systemName: slide.symbol, withConfiguration: config)
        }

        let title = UILabel(frame: CGRect(x: 24, y: image.frame.maxY + 28, width: frame.width - 48, height: 32))
        title.text = slide.title
        title.textAlignment = .center
        title.textColor = Brand.accent
        title.font = .systemFont(ofSize: 24, weight: .bold)

        let detail = UILabel(frame: CGRect(x: 32, y: title.frame.maxY + 12, width: frame.width - 64, height: 72))
        detail.text = slide.detail
        detail.textAlignment = .center
        detail.textColor = Brand.textSecondary
        detail.font = .systemFont(ofSize: 15)
        detail.numberOfLines = 0

        container.addSubview(image)
        container.addSubview(title)
        container.addSubview(detail)
        return container
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        pageControl.currentPage = page
        updateActionTitle()
        if page == 0 {
            player?.play()
        } else {
            player?.pause()
        }
    }

    private func updateActionTitle() {
        let title = pageControl.currentPage == pageCount - 1 ? "立即体验" : "下一步"
        actionButton.setTitle(title, for: .normal)
    }

    @objc private func advance() {
        let next = pageControl.currentPage + 1
        if next >= pageCount {
            finishGuide()
            return
        }
        let width = scrollView.bounds.width
        scrollView.setContentOffset(CGPoint(x: width * CGFloat(next), y: 0), animated: true)
        pageControl.currentPage = next
        updateActionTitle()
        if next == 0 {
            player?.play()
        } else {
            player?.pause()
        }
    }

    private func stopVideo() {
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
            self.loopObserver = nil
        }
        player?.pause()
        player = nil
    }

    @objc private func finishGuide() {
        stopVideo()
        AppPrefs.isGuideShown = true
        guard let window = view.window else { return }
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = MainViewController()
        }
    }
}
