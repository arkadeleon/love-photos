//
//  AssetPreviewNavigationController.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/10/23.
//

import UIKit

class AssetPreviewNavigationController: UINavigationController {

    private var interactiveController: UIPercentDrivenInteractiveTransition?

    init(manager: AssetManager, asset: Asset, assets: [Asset]) {
        let previewViewController = AssetPreviewViewController(manager: manager, asset: asset, assets: assets)
        super.init(rootViewController: previewViewController)

        modalPresentationStyle = .custom
        transitioningDelegate = self

        isToolbarHidden = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
    }

    @objc
    private func handlePan(_ panGestureRecognizer: UIPanGestureRecognizer) {
        guard let window = view.window else {
            return
        }

        switch panGestureRecognizer.state {
        case .began:
            let velocity = panGestureRecognizer.velocity(in: window)
            if abs(velocity.y) > abs(velocity.x) {
                interactiveController = UIPercentDrivenInteractiveTransition()
                dismiss(animated: true)
            }
        case .changed:
            let translation = panGestureRecognizer.translation(in: window)
            let progress = translation.y / window.bounds.height * 2.5
            interactiveController?.update(progress)
        case .ended:
            let velocity = panGestureRecognizer.velocity(in: window)
            if velocity.y > 0 {
                interactiveController?.finish()
            } else {
                interactiveController?.cancel()
            }
            interactiveController = nil
        default:
            interactiveController?.cancel()
            interactiveController = nil
        }
    }
}

extension AssetPreviewNavigationController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        AssetPresentationTransitionAnimator()
    }

    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        AssetDismissalTransitionAnimator()
    }

    func interactionControllerForDismissal(using animator: any UIViewControllerAnimatedTransitioning) -> (any UIViewControllerInteractiveTransitioning)? {
        interactiveController
    }
}
