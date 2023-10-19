//
//  ObjectsPreviewViewController.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/16.
//

import UIKit

class ObjectsPreviewViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    let manager: S3ObjectManager
    let objects: [S3Object]
    private(set) var currentObject: S3Object

    var pageViewController: UIPageViewController!

    init(manager: S3ObjectManager, objects: [S3Object], currentObject: S3Object) {
        self.manager = manager
        self.objects = objects
        self.currentObject = currentObject
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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

        let previewViewController = previewViewController(for: currentObject)
        pageViewController.setViewControllers([previewViewController], direction: .forward, animated: false)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = objects.firstIndex(of: currentObject) else {
            return nil
        }

        let previousIndex = index - 1
        guard previousIndex >= 0 else {
            return nil
        }

        let object = objects[previousIndex]
        let previewViewController = previewViewController(for: object)
        return previewViewController
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = objects.firstIndex(of: currentObject) else {
            return nil
        }

        let nextIndex = index + 1
        guard nextIndex < objects.count else {
            return nil
        }

        let object = objects[nextIndex]
        let previewViewController = previewViewController(for: object)
        return previewViewController
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if let previewViewController = pageViewController.viewControllers?.first as? PhotoObjectPreviewViewController {
                currentObject = previewViewController.object
            } else if let previewViewController = pageViewController.viewControllers?.first as? VideoObjectPreviewViewController {
                currentObject = previewViewController.object
            }
        }
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
