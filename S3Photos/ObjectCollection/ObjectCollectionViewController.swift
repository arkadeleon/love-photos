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

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: PersistenceController.shared.context, sectionNameKeyPath: "rawType", cacheName: nil)
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

        let folderCellRegistration = UICollectionView.CellRegistration<FolderObjectCollectionViewCell, NSManagedObjectID> { cell, indexPath, objectID in
            let object = self.fetchedResultsController.object(at: indexPath)
            cell.configure(withManager: self.manager, object: object)
        }

        let imageCellRegistration = UICollectionView.CellRegistration<ImageObjectCollectionViewCell, NSManagedObjectID> { cell, indexPath, objectID in
            let object = self.fetchedResultsController.object(at: indexPath)
            cell.configure(withManager: self.manager, object: object)
        }

        let videoCellRegistration = UICollectionView.CellRegistration<VideoObjectCollectionViewCell, NSManagedObjectID> { cell, indexPath, objectID in
            let object = self.fetchedResultsController.object(at: indexPath)
            cell.configure(withManager: self.manager, object: object)
        }

        let unknownCellRegistration = UICollectionView.CellRegistration<UnknownObjectCollectionViewCell, NSManagedObjectID> { cell, indexPath, objectID in
            let object = self.fetchedResultsController.object(at: indexPath)
            cell.configure(withManager: self.manager, object: object)
        }

        diffableDataSource = UICollectionViewDiffableDataSource<Int, NSManagedObjectID>(collectionView: collectionView) { collectionView, indexPath, objectID in
            let object = self.fetchedResultsController.object(at: indexPath)
            switch (object.type, object.fileMediaType) {
            case (.folder, _):
                let cell = collectionView.dequeueConfiguredReusableCell(using: folderCellRegistration, for: indexPath, item: objectID)
                return cell
            case (.file, .image):
                let cell = collectionView.dequeueConfiguredReusableCell(using: imageCellRegistration, for: indexPath, item: objectID)
                return cell
            case (.file, .video):
                let cell = collectionView.dequeueConfiguredReusableCell(using: videoCellRegistration, for: indexPath, item: objectID)
                return cell
            default:
                let cell = collectionView.dequeueConfiguredReusableCell(using: unknownCellRegistration, for: indexPath, item: objectID)
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
        case .folder:
            let fetchRequest = NSFetchRequest<S3Object>(entityName: "S3Object")
            fetchRequest.predicate = NSPredicate(format: "prefix == %@ && key != %@", object.key!, object.key!)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "rawType", ascending: true),
                NSSortDescriptor(key: "key", ascending: true)
            ]

            let objectCollectionViewController = ObjectCollectionViewController(manager: manager, fetchRequest: fetchRequest)
            objectCollectionViewController.title = object.name

            navigationController?.pushViewController(objectCollectionViewController, animated: true)

            Task {
                try await manager.listObjects(prefix: object.key!)
            }
        case .file:
            let objects = fetchedResultsController.fetchedObjects?.filter({ $0.type == .file }) ?? []
            let previewNavigationController = ObjectPreviewNavigationController(manager: manager, object: object, objects: objects)
            present(previewNavigationController, animated: true)
        default:
            fatalError()
        }
    }
}

extension ObjectCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch fetchedResultsController.object(at: indexPath).type {
        case .folder:
            let numberOfCells: CGFloat = 2
            let width = floor((collectionView.bounds.size.width - (numberOfCells + 1) * 16) / numberOfCells)
            let height = width
            let size = CGSize(width: width, height: height + 30)
            return size
        case .file:
            let numberOfCells: CGFloat = 3
            let width = floor((collectionView.bounds.size.width - (numberOfCells - 1) * 2) / numberOfCells)
            let height = width
            let size = CGSize(width: width, height: height)
            return size
        default:
            fatalError()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch fetchedResultsController.sections?[section].name {
        case S3ObjectType.folder.rawValue:
            UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        case S3ObjectType.file.rawValue:
            .zero
        default:
            fatalError()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch fetchedResultsController.sections?[section].name {
        case S3ObjectType.folder.rawValue: 
            16
        case S3ObjectType.file.rawValue: 
            2
        default: 
            fatalError()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        switch fetchedResultsController.sections?[section].name {
        case S3ObjectType.folder.rawValue: 
            16
        case S3ObjectType.file.rawValue: 
            2
        default: 
            fatalError()
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
