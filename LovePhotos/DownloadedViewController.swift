//
//  DownloadedViewController.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/10/17.
//

import CoreData
import UIKit

class DownloadedViewController: UIViewController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        title = "Downloaded"

        tabBarItem = UITabBarItem(
            title: "Downloaded",
            image: UIImage(systemName: "arrow.down.circle"),
            selectedImage: UIImage(systemName: "arrow.down.circle.fill")
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        if let account = AccountManager.shared.activeAccount {
            addAssetCollectionViewController(withAccount: account)
        }
    }

    private func addAssetCollectionViewController(withAccount account: Account) {
        let manager = AssetManager(account: account)

        let fetchRequest = Asset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "rawType == %@ && creationDate != NULL", AssetType.file.rawValue)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]

        let assetCollectionViewController = AssetCollectionViewController(manager: manager, fetchRequest: fetchRequest)

        addChild(assetCollectionViewController)
        assetCollectionViewController.view.frame = view.bounds
        assetCollectionViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(assetCollectionViewController.view)
        assetCollectionViewController.didMove(toParent: self)
    }
}
