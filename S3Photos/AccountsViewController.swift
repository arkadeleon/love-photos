//
//  AccountsViewController.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/18.
//

import UIKit

class AccountsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let addAccountAction = UIAction(image: UIImage(systemName: "plus.circle")) { _ in
            self.presentAddAccountAlertController()
        }
        let addAcountItem = UIBarButtonItem(primaryAction: addAccountAction)
        navigationItem.rightBarButtonItem = addAcountItem

        addAccountCollectionViewController()
    }

    private func addAccountCollectionViewController() {
        let accountCollectionViewController = AccountCollectionViewController()

        addChild(accountCollectionViewController)
        view.addSubview(accountCollectionViewController.view)
        accountCollectionViewController.didMove(toParent: self)

        accountCollectionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        accountCollectionViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        accountCollectionViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        accountCollectionViewController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        accountCollectionViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    private func presentAddAccountAlertController() {
        let alert = UIAlertController(title: "Add Account", message: nil, preferredStyle: .alert)

        alert.addTextField { accessKeyIdTextField in
            accessKeyIdTextField.placeholder = "Access Key ID"
        }

        alert.addTextField { secretAccessKeyTextField in
            secretAccessKeyTextField.placeholder = "Secret Access Key"
        }

        alert.addTextField { endpointTextField in
            endpointTextField.placeholder = "Endpoint"
        }

        alert.addTextField { bucketTextField in
            bucketTextField.placeholder = "Bucket"
        }

        let accessKeyIdTextField = alert.textFields![0]
        let secretAccessKeyTextField = alert.textFields![1]
        let endpointTextField = alert.textFields![2]
        let bucketTextField = alert.textFields![3]

        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancel)

        let add = UIAlertAction(title: "Add", style: .default) { _ in
            let accessKeyId = accessKeyIdTextField.text
            let secretAccessKey = secretAccessKeyTextField.text
            let endpoint = endpointTextField.text
            let bucket = bucketTextField.text

            let context = PersistenceController.shared.container.viewContext
            let account = S3Account(context: context)
            account.accessKeyId = accessKeyId
            account.secretAccessKey = secretAccessKey
            account.endpoint = endpoint
            account.bucket = bucket

            PersistenceController.shared.saveContext()
        }
        alert.addAction(add)

        present(alert, animated: true)
    }
}
