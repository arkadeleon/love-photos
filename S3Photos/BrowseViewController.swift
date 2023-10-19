//
//  BrowseViewController.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/17.
//

import CoreData
import UIKit

class BrowseViewController: UIViewController {

    let prefix: String

    init(prefix: String = "") {
        self.prefix = prefix

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

        if let account = S3AccountManager.shared.activeAccount {
            addObjectCollectionViewController(withAccount: account)
        }
    }

    private func addObjectCollectionViewController(withAccount account: S3Account) {
        let manager = S3ObjectManager(account: account)

        let fetchRequest = NSFetchRequest<S3Object>(entityName: "S3Object")
        fetchRequest.predicate = NSPredicate(format: "prefix == %@ && key != %@", prefix, prefix)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "key", ascending: true)]

        let objectCollectionViewController = ObjectCollectionViewController(manager: manager, fetchRequest: fetchRequest)

        addChild(objectCollectionViewController)
        view.addSubview(objectCollectionViewController.view)
        objectCollectionViewController.didMove(toParent: self)

        objectCollectionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        objectCollectionViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        objectCollectionViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        objectCollectionViewController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        objectCollectionViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        Task {
            try await manager.listObjects(prefix: prefix)
        }
    }
}
