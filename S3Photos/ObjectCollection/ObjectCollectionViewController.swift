//
//  ObjectCollectionViewController.swift
//  S3Photos
//
//  Created by Leon Li on 2023/9/26.
//

import CoreData
import UIKit

class ObjectCollectionViewController: UIViewController {

    let manager: S3ObjectManager
    let fetchRequest: NSFetchRequest<S3Object>

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

        addObjectCollectionView()

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: PersistenceController.shared.context, sectionNameKeyPath: "isGroup", cacheName: nil)
        fetchedResultsController.delegate = self

        Task {
            try await PersistenceController.shared.context.perform {
                try self.fetchedResultsController.performFetch()
            }
        }
    }

    private func addObjectCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self

        let groupObjectCellRegistration = UICollectionView.CellRegistration<GroupObjectCollectionViewCell, NSManagedObjectID> { cell, indexPath, objectID in
            let object = self.fetchedResultsController.object(at: indexPath)
            cell.configure(withManager: self.manager, object: object)
        }

        let photoObjectCellRegistration = UICollectionView.CellRegistration<PhotoObjectCollectionViewCell, NSManagedObjectID> { cell, indexPath, objectID in
            let object = self.fetchedResultsController.object(at: indexPath)
            cell.configure(withManager: self.manager, object: object)
        }

        let videoObjectCellRegistration = UICollectionView.CellRegistration<VideoObjectCollectionViewCell, NSManagedObjectID> { cell, indexPath, objectID in
            let object = self.fetchedResultsController.object(at: indexPath)
            cell.configure(withManager: self.manager, object: object)
        }

        let otherObjectCellRegistration = UICollectionView.CellRegistration<OtherObjectCollectionViewCell, NSManagedObjectID> { cell, indexPath, objectID in
            let object = self.fetchedResultsController.object(at: indexPath)
            cell.configure(withManager: self.manager, object: object)
        }

        diffableDataSource = UICollectionViewDiffableDataSource<Int, NSManagedObjectID>(collectionView: collectionView) { collectionView, indexPath, objectID in
            let object = self.fetchedResultsController.object(at: indexPath)
            switch object.type {
            case .group:
                let cell = collectionView.dequeueConfiguredReusableCell(using: groupObjectCellRegistration, for: indexPath, item: objectID)
                return cell
            case .photo:
                let cell = collectionView.dequeueConfiguredReusableCell(using: photoObjectCellRegistration, for: indexPath, item: objectID)
                return cell
            case .video:
                let cell = collectionView.dequeueConfiguredReusableCell(using: videoObjectCellRegistration, for: indexPath, item: objectID)
                return cell
            case .other:
                let cell = collectionView.dequeueConfiguredReusableCell(using: otherObjectCellRegistration, for: indexPath, item: objectID)
                return cell
            }
        }
        collectionView.dataSource = diffableDataSource

        view.addSubview(collectionView)
    }
}

extension ObjectCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let object = fetchedResultsController.object(at: indexPath)
        switch object.type {
        case .group:
            let fetchRequest = NSFetchRequest<S3Object>(entityName: "S3Object")
            fetchRequest.predicate = NSPredicate(format: "prefix == %@ && key != %@", object.key!, object.key!)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "key", ascending: true)]

            let objectCollectionViewController = ObjectCollectionViewController(manager: manager, fetchRequest: fetchRequest)
            objectCollectionViewController.title = object.name

            navigationController?.pushViewController(objectCollectionViewController, animated: true)

            Task {
                try await manager.listObjects(prefix: object.key!)
            }
        case .photo, .video:
            let objects = fetchedResultsController.fetchedObjects?.filter({ $0.type == .photo || $0.type == .video }) ?? []
            let previewNavigationController = ObjectPreviewNavigationController(manager: manager, object: object, objects: objects)
            present(previewNavigationController, animated: true)
        case .other:
            break
        }
    }
}

extension ObjectCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let object = fetchedResultsController.object(at: indexPath)
        switch object.type {
        case .group:
            let numberOfCells: CGFloat = 2
            let width = floor((collectionView.bounds.size.width - (numberOfCells + 1) * 16) / numberOfCells)
            let height = width
            let size = CGSize(width: width, height: height + 30)
            return size
        default:
            let numberOfCells: CGFloat = 3
            let width = floor((collectionView.bounds.size.width - (numberOfCells - 1) * 2) / numberOfCells)
            let height = width
            let size = CGSize(width: width, height: height)
            return size
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch fetchedResultsController.sectionIndexTitles[section] {
        case "1":
            return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        default:
            return UIEdgeInsets.zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch fetchedResultsController.sectionIndexTitles[section] {
        case "1":
            return 16
        default:
            return 2
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        switch fetchedResultsController.sectionIndexTitles[section] {
        case "1":
            return 16
        default:
            return 2
        }
    }
}

extension ObjectCollectionViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        Task {
            await MainActor.run {
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
}
