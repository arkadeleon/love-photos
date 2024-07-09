//
//  PersistenceController.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/9/25.
//

import CoreData
import SotoS3
import UIKit

class PersistenceController {

    static let shared = PersistenceController()

    let container: NSPersistentContainer
    let context: NSManagedObjectContext

    init() {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        container = NSPersistentContainer(name: "CloudStorage")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })

        context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
    }

    func fetchAssets(for account: Account, parentIdentifier: String) async throws -> [Asset] {
        try context.performAndWait {
            let fetchRequest = Asset.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "parentIdentifier == %@ && identifier != %@", parentIdentifier, parentIdentifier)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "name", ascending: true)
            ]
            return try context.fetch(fetchRequest)
        }
    }

    func insertAssetList(_ assetList: AssetList) async throws {
        try context.performAndWait {
            for item in assetList.items {
                let fetchRequest = Asset.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "identifier == %@", item.identifier)
                let result = try context.fetch(fetchRequest)
                guard result.isEmpty else {
                    continue
                }

                let asset = Asset(context: context, item: item)
            }

            try context.save()
        }
    }

    func saveThumbnail(_ thumbnail: UIImage, for asset: Asset) async throws {
        try context.performAndWait {
            asset.thumbnail = thumbnail

            try context.save()
        }
    }

    func saveMetadata(_ metadata: AssetMetadata, for asset: Asset) async throws {
        try context.performAndWait {
            asset.creationDate = metadata.creationDate
            asset.duration = metadata.duration ?? 0

            try context.save()
        }
    }

    func deleteAllAssets(for account: Account) async throws {
        try context.performAndWait {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Asset")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try self.container.persistentStoreCoordinator.execute(deleteRequest, with: context)
        }
    }

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
