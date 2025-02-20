//
//  BrowseViewController.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/10/17.
//

import CoreData
import UIKit

class BrowseViewController: UIViewController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        title = "Browse"

        tabBarItem = UITabBarItem(
            title: "Browse",
            image: UIImage(systemName: "photo.circle"),
            selectedImage: UIImage(systemName: "photo.circle.fill")
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
        let parentIdentifier = account.field5 ?? ""

        let fetchRequest = Asset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "parentIdentifier == %@ && identifier != %@", parentIdentifier, parentIdentifier)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "rawType", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ]

        let manager = AssetManager(account: account)
        let assetCollectionViewController = AssetCollectionViewController(manager: manager, fetchRequest: fetchRequest)

        addChild(assetCollectionViewController)
        assetCollectionViewController.view.frame = view.bounds
        assetCollectionViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(assetCollectionViewController.view)
        assetCollectionViewController.didMove(toParent: self)
    }
}
