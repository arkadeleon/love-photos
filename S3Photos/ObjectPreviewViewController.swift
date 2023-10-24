//
//  ObjectPreviewViewController.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/16.
//

import UIKit

class ObjectPreviewViewController: UIViewController {

    let manager: S3ObjectManager
    private(set) var object: S3Object
    let objects: [S3Object]

    var pageViewController: UIPageViewController!

    init(manager: S3ObjectManager, object: S3Object, objects: [S3Object]) {
        self.manager = manager
        self.object = object
        self.objects = objects

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

        let previewViewController = previewViewController(for: object)
        pageViewController.setViewControllers([previewViewController], direction: .forward, animated: false)

        title = previewViewController.title
    }

    private func previewViewController(for object: S3Object) -> UIViewController {
        switch object.type {
        case .photo:
            let previewViewController = PhotoObjectPreviewViewController(manager: manager, object: object)
            return previewViewController
        case .video:
            let previewViewController = VideoObjectPreviewViewController(manager: manager, object: object)
            return previewViewController
        default:
            fatalError()
        }
    }
}

extension ObjectPreviewViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = objects.firstIndex(of: object) else {
            return nil
        }

        let previousIndex = index - 1
        guard previousIndex >= 0 else {
            return nil
        }

        let previousObject = objects[previousIndex]
        let previewViewController = previewViewController(for: previousObject)
        return previewViewController
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = objects.firstIndex(of: object) else {
            return nil
        }

        let nextIndex = index + 1
        guard nextIndex < objects.count else {
            return nil
        }

        let nextObject = objects[nextIndex]
        let previewViewController = previewViewController(for: nextObject)
        return previewViewController
    }
}

extension ObjectPreviewViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if let previewViewController = pageViewController.viewControllers?.first as? PhotoObjectPreviewViewController {
                title = previewViewController.title
                object = previewViewController.object
            } else if let previewViewController = pageViewController.viewControllers?.first as? VideoObjectPreviewViewController {
                title = previewViewController.title
                object = previewViewController.object
            }
        }
    }
}
