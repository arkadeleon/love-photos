//
//  AccountCollectionViewController.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/10/18.
//

import CoreData
import SVProgressHUD
import UIKit

class AccountCollectionViewController: UIViewController {

    private var collectionView: UICollectionView!
    private var diffableDataSource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID>!
    private var fetchedResultsController: NSFetchedResultsController<Account>!

    override func viewDidLoad() {
        super.viewDidLoad()

        addAccountCollectionView()

        let fetchRequest = Account.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "objectID", ascending: true)]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: PersistenceController.shared.context, sectionNameKeyPath: "objectID", cacheName: nil)
        fetchedResultsController.delegate = self

        Task {
            try await PersistenceController.shared.context.perform {
                try self.fetchedResultsController.performFetch()
            }
        }
    }

    private func addAccountCollectionView() {
        let listConfiguration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let listLayout = UICollectionViewCompositionalLayout.list(using: listConfiguration)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: listLayout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self

        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, NSManagedObjectID> { cell, indexPath, objectID in
            let account = self.fetchedResultsController.object(at: indexPath)

            let fields: [any AccountField] = switch account.type {
            case .s3: S3AccountField.allFields
            default: []
            }

            let values = fields.enumerated().map { (index, field) in
                let value = account.value(forFieldAt: index) ?? ""
                return field.isSecure ? value.map({ _ in "*" }).joined() : value
            }

            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.image = UIImage(systemName: "person.circle")
            contentConfiguration.text = values.joined(separator: "\n")
            cell.contentConfiguration = contentConfiguration

            let clearCacheAction = UIAction(title: "Clear Cache", image: UIImage(systemName: "trash"), attributes: [.destructive]) { _ in
                Task {
                    try await PersistenceController.shared.deleteAllAssets(for: account)
                }
            }
            let synchronizeAction = UIAction(title: "Synchronize", image: UIImage(systemName: "arrow.trianglehead.2.clockwise.rotate.90")) { _ in
                Task { @MainActor in
                    SVProgressHUD.show(withStatus: "Synchronizing...")

                    let manager = AssetManager(account: account)
                    try await manager.synchronizeAssets()

                    await SVProgressHUD.dismiss()
                }
            }
            let menu = UIMenu(options: .displayInline, children: [synchronizeAction, clearCacheAction])
            let button = UIButton(type: .custom)
            button.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
            button.menu = menu
            button.showsMenuAsPrimaryAction = true
            let checkmark = UICellAccessory.checkmark(options: .init(isHidden: !account.isActive))
            let more = UICellAccessory.customView(configuration: .init(customView: button, placement: .trailing(displayed: .always, at: UICellAccessory.Placement.position(before: checkmark))))
            cell.accessories = [checkmark, more]
        }

        diffableDataSource = UICollectionViewDiffableDataSource<Int, NSManagedObjectID>(collectionView: collectionView) { collectionView, indexPath, objectID in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: objectID)
            return cell
        }
        collectionView.dataSource = diffableDataSource

        view.addSubview(collectionView)
    }
}

extension AccountCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let accounts = fetchedResultsController.fetchedObjects ?? []
        let selectedAccount = fetchedResultsController.object(at: indexPath)

        for account in accounts {
            account.isActive = account == selectedAccount
        }

        PersistenceController.shared.saveContext()

        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension AccountCollectionViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        Task { @MainActor in
            guard let dataSource = collectionView?.dataSource as? UICollectionViewDiffableDataSource<Int, NSManagedObjectID> else {
                assertionFailure("The data source has not implemented snapshot support while it should")
                return
            }
            var snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
            let currentSnapshot = dataSource.snapshot() as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>

            let reloadIdentifiers: [NSManagedObjectID] = snapshot.itemIdentifiers.compactMap { itemIdentifier in
                guard let currentIndex = currentSnapshot.indexOfItem(itemIdentifier), let index = snapshot.indexOfItem(itemIdentifier), index == currentIndex else {
                    return nil
                }
                guard let existingObject = try? controller.managedObjectContext.existingObject(with: itemIdentifier), existingObject.isUpdated else { return nil }
                return itemIdentifier
            }
            snapshot.reloadItems(reloadIdentifiers)

            let shouldAnimate = collectionView?.numberOfSections != 0
            dataSource.apply(snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>, animatingDifferences: shouldAnimate)
        }
    }
}
