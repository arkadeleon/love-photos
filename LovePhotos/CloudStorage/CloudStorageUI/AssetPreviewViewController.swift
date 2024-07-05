//
//  AssetPreviewViewController.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/10/16.
//

import UIKit

class AssetPreviewViewController: UIViewController {

    let manager: AssetManager
    private(set) var asset: Asset
    let assets: [Asset]

    var pageViewController: UIPageViewController!

    init(manager: AssetManager, asset: Asset, assets: [Asset]) {
        self.manager = manager
        self.asset = asset
        self.assets = assets

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navigationItem.scrollEdgeAppearance = appearance

        let backAction = UIAction(image: UIImage(systemName: "chevron.left")) { _ in
            self.dismiss(animated: true)
        }
        let backItem = UIBarButtonItem(primaryAction: backAction)

        navigationItem.leftBarButtonItem = backItem

        let shareAction = UIAction(image: UIImage(systemName: "square.and.arrow.up")) { _ in
            // Share
        }
        let shareItem = UIBarButtonItem(primaryAction: shareAction)

        toolbarItems = [
            shareItem,
        ]

        addPageViewController()
    }

    private func addPageViewController() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageViewController.dataSource = self
        pageViewController.delegate = self

        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)

        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let previewViewController = previewViewController(for: asset)
        pageViewController.setViewControllers([previewViewController], direction: .forward, animated: false)

        title = previewViewController.title
    }

    private func previewViewController(for asset: Asset) -> UIViewController {
        switch asset.mediaType {
        case .image:
            let previewViewController = ImageAssetPreviewViewController(manager: manager, asset: asset)
            return previewViewController
        case .video:
            let previewViewController = VideoAssetPreviewViewController(manager: manager, asset: asset)
            return previewViewController
        default:
            let previewViewController = UIViewController()
            return previewViewController
        }
    }
}

extension AssetPreviewViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = assets.firstIndex(of: asset) else {
            return nil
        }

        let previousIndex = index - 1
        guard previousIndex >= 0 else {
            return nil
        }

        let previousAsset = assets[previousIndex]
        let previewViewController = previewViewController(for: previousAsset)
        return previewViewController
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = assets.firstIndex(of: asset) else {
            return nil
        }

        let nextIndex = index + 1
        guard nextIndex < assets.count else {
            return nil
        }

        let nextAsset = assets[nextIndex]
        let previewViewController = previewViewController(for: nextAsset)
        return previewViewController
    }
}

extension AssetPreviewViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if let previewViewController = pageViewController.viewControllers?.first as? ImageAssetPreviewViewController {
                title = previewViewController.title
                asset = previewViewController.asset
            } else if let previewViewController = pageViewController.viewControllers?.first as? VideoAssetPreviewViewController {
                title = previewViewController.title
                asset = previewViewController.asset
            }
        }
    }
}
