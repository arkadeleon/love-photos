//
//  AccountsViewController.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/10/18.
//

import UIKit

class AccountsViewController: UIViewController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        title = "Accounts"

        tabBarItem = UITabBarItem(
            title: "Accounts",
            image: UIImage(systemName: "person.circle"),
            selectedImage: UIImage(systemName: "person.circle.fill")
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let newAccountAction = UIAction(image: UIImage(systemName: "plus.circle")) { _ in
            self.presentNewAccountViewController(type: .s3)
        }
        let newAcountItem = UIBarButtonItem(primaryAction: newAccountAction)
        navigationItem.rightBarButtonItem = newAcountItem

        addAccountCollectionViewController()
    }

    private func addAccountCollectionViewController() {
        let accountCollectionViewController = AccountCollectionViewController()

        addChild(accountCollectionViewController)
        accountCollectionViewController.view.frame = view.bounds
        accountCollectionViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(accountCollectionViewController.view)
        accountCollectionViewController.didMove(toParent: self)
    }

    private func presentNewAccountViewController(type: AccountType) {
        let alert = UIAlertController(title: "New Account", message: nil, preferredStyle: .alert)

        let fields = switch type {
        case .s3: S3AccountField.allFields
        }

        for field in fields {
            alert.addTextField { textField in
                textField.placeholder = field.title
                textField.isSecureTextEntry = field.isSecure
            }
        }

        let textFields = alert.textFields ?? []

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)

        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            let context = PersistenceController.shared.context

            let account = Account(context: context)
            account.identifier = UUID().uuidString
            account.rawType = type.rawValue

            for (index, textField) in textFields.enumerated() {
                account.setValue(textField.text, forFieldAt: index)
            }

            PersistenceController.shared.saveContext()
        }
        alert.addAction(saveAction)

        present(alert, animated: true)
    }
}
