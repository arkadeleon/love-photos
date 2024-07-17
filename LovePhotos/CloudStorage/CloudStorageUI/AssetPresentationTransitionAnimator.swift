//
//  AssetPresentationTransitionAnimator.swift
//  LovePhotos
//
//  Created by Leon Li on 2024/7/16.
//

import UIKit

class AssetPresentationTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        0.25
    }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        transitionContext.containerView.addSubview(toView)
        toView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)

        UIView.animate(withDuration: 0.25) {
            toView.transform = .identity
        } completion: { finished in
            transitionContext.completeTransition(finished)
        }
    }
}
