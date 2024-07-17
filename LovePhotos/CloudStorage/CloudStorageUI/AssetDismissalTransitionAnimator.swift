//
//  AssetDismissalTransitionAnimator.swift
//  LovePhotos
//
//  Created by Leon Li on 2024/7/16.
//

import UIKit

class AssetDismissalTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        0.25
    }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }

        UIView.animate(withDuration: 0.25) {
            fromView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        } completion: { finished in
            transitionContext.completeTransition(finished)
        }
    }
}
