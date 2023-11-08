//
//  BrowseViewController.swift
//  CloudPhotos
//
//  Created by Leon Li on 2023/10/17.
//

import CoreData
import UIKit

class BrowseViewController: UIViewController {

    let parentIdentifier: String

    init(parentIdentifier: String = "") {
        self.parentIdentifier = parentIdentifier

        super.init(nibName: nil, bundle: nil)

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
        let manager = AssetManager(account: account)

        let fetchRequest = Asset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "parentIdentifier == %@ && identifier != %@", parentIdentifier, parentIdentifier)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "rawType", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ]

        let assetCollectionViewController = AssetCollectionViewController(manager: manager, fetchRequest: fetchRequest)

        addChild(assetCollectionViewController)
        view.addSubview(assetCollectionViewController.view)
        assetCollectionViewController.didMove(toParent: self)

        assetCollectionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        assetCollectionViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        assetCollectionViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        assetCollectionViewController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        assetCollectionViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        Task {
            try await manager.assetList(for: parentIdentifier)
        }
    }
}
