//
//  PersistenceController.swift
//  S3Photos
//
//  Created by Leon Li on 2023/9/25.
//

import CoreData

class PersistenceController {

    static let shared = PersistenceController()

    let container: NSPersistentContainer

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
    }

    func fetchObjects(for account: S3Account, prefix: String) throws -> [S3Object] {
        let fetchRequest = S3Object.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "prefix == %@ && key != %@", prefix, prefix)
        let result = try container.viewContext.fetch(fetchRequest)
        return result
    }

    func deleteAllObjects(for account: S3Account) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "S3Object")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try container.persistentStoreCoordinator.execute(deleteRequest, with: container.viewContext)
        } catch {

        }
    }

    func saveContext() {
        let context = container.viewContext
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
