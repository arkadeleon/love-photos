//
//  PersistenceController.swift
//  S3Photos
//
//  Created by Leon Li on 2023/9/25.
//

import CoreData
import SotoS3

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
        container = NSPersistentContainer(name: "S3Photos")
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

    func fetchObjects(for account: S3Account, prefix: String) async throws -> [S3Object] {
        try context.performAndWait {
            let fetchRequest = S3Object.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "prefix == %@ && key != %@", prefix, prefix)
            return try context.fetch(fetchRequest)
        }
    }

    func insertObjects(_ objs: [S3.Object], prefix: String) async throws {
        try context.performAndWait {
            for obj in objs {
                guard let key = obj.key else {
                    continue
                }

                let fetchRequest = S3Object.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "key == %@", key)
                let result = try context.fetch(fetchRequest)
                guard result.isEmpty else {
                    continue
                }

                let object = S3Object(context: context)
                object.prefix = prefix
                object.eTag = obj.eTag
                object.key = obj.key
                object.lastModified = obj.lastModified
                object.size = obj.size ?? 0
                object.isGroup = object.type == .group
            }

            try context.save()
        }
    }

    func deleteAllObjects(for account: S3Account) async throws {
        try context.performAndWait {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "S3Object")
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
