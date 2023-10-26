//
//  ObjectPreviewNavigationController.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/23.
//

import UIKit

class ObjectPreviewNavigationController: UINavigationController {

    init(manager: S3ObjectManager, object: S3Object, objects: [S3Object]) {
        let previewViewController = ObjectPreviewViewController(manager: manager, object: object, objects: objects)
        super.init(rootViewController: previewViewController)

        modalTransitionStyle = .coverVertical
        modalPresentationStyle = .fullScreen

        isToolbarHidden = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
