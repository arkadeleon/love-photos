//
//  ObjectCollectionViewController.swift
//  S3Photos
//
//  Created by Leon Li on 2023/9/26.
//

import CoreData
import UIKit

@MainActor protocol ObjectCollectionViewControllerDelegate: NSObjectProtocol {
    func objectCollectionViewController(_ viewController: ObjectCollectionViewController, didSelectFolderObject object: S3Object)
}

class ObjectCollectionViewController: UIViewController {

    let manager: S3ObjectManager
    let fetchRequest: NSFetchRequest<S3Object>

    weak var delegate: ObjectCollectionViewControllerDelegate?

    private var collectionView: UICollectionView!
    private var diffableDataSource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID>!
    private var fetchedResultsController: NSFetchedResultsController<S3Object>!

    init(manager: S3ObjectManager, fetchRequest: NSFetchRequest<S3Object>) {
        self.manager = manager
        self.fetchRequest = fetchRequest
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 2
        flowLayout.minimumInteritemSpacing = 2

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self
        collectionView.register(ObjectCollectionViewCell.self, forCellWithReuseIdentifier: "S3ObjectCollectionViewCell")

        diffableDataSource = UICollectionViewDiffableDataSource<Int, NSManagedObjectID>(collectionView: collectionView) { collectionView, indexPath, objectID in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "S3ObjectCollectionViewCell", for: indexPath) as! ObjectCollectionViewCell
            let object = PersistenceController.shared.container.viewContext.object(with: objectID) as! S3Object
            cell.configure(withManager: self.manager, object: object)
            return cell
        }
        collectionView.dataSource = diffableDataSource

        view.addSubview(collectionView)

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: PersistenceController.shared.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
    }
}

extension ObjectCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let itemIdentifier = diffableDataSource.itemIdentifier(for: indexPath) else {
            return
        }

        guard let object = PersistenceController.shared.container.viewContext.object(with: itemIdentifier) as? S3Object else {
            return
        }

        switch object.type {
        case .folder:
            delegate?.objectCollectionViewController(self, didSelectFolderObject: object)
        case .photo, .video:
            let objects = fetchedResultsController.fetchedObjects?.filter({ $0.type == .photo || $0.type == .video }) ?? []
            let previewViewController = ObjectsPreviewViewController(manager: manager, objects: objects, currentObject: object)
            present(previewViewController, animated: true)
        case .other:
            break
        }
    }
}

extension ObjectCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfCells: CGFloat = 3
        let width = floor((collectionView.bounds.size.width - (numberOfCells - 1) * 2) / numberOfCells)
        let height = width
        let size = CGSize(width: width, height: height)
        return size
    }
}

extension ObjectCollectionViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
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
