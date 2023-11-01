//
//  AssetPreviewNavigationController.swift
//  CloudPhotos
//
//  Created by Leon Li on 2023/10/23.
//

import UIKit

class AssetPreviewNavigationController: UINavigationController {

    init(manager: AssetManager, asset: Asset, assets: [Asset]) {
        let previewViewController = AssetPreviewViewController(manager: manager, asset: asset, assets: assets)
        super.init(rootViewController: previewViewController)

        modalTransitionStyle = .coverVertical
        modalPresentationStyle = .fullScreen

        isToolbarHidden = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
