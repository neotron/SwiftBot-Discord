//
// Created by David Hedbor on 2/15/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Singleton managing access to the database
//

import Foundation
import CoreData
import DiscordAPI

class CoreDataManager : NSObject {
    static let instance = CoreDataManager()

    lazy private var persistentStoreCoordinator = CoreDataManager.instance.createPersistentStoreCoordinator()
    lazy private var managedObjectModel = CoreDataManager.instance.createManagedObjectModel()
    lazy private var managedObjectContext = CoreDataManager.instance.createManagedObjectContext()

    override init() {
        super.init()
    }

    func isSetupAndWorking() -> Bool {
        return self.persistentStoreCoordinator != nil
    }

}

// MARK: Custom commands helper functions
extension CoreDataManager {
    // Return the command with the specified name, or nil if there isn't one
    func loadCommandAlias(command: String) -> CommandAlias? {
        let predicate = NSPredicate(format: "command = %@", argumentArray: [command.lowercaseString])
        if let matches = self.fetchObjectsOfType(.CommandAlias, withPredicate: predicate) {
            var match: AnyObject?
            switch matches.count {
            case 0:
                return nil
            case 1:
                match = matches[0]
            default:
                LOG_DEBUG("Found multiple matches for command \(command)! Returning first match")
                match = matches[1]
            }
            if let command = match as? CommandAlias {
                return command
            }
            LOG_ERROR("Query for command returned non-command object \(match)")
        }
        return nil
    }

    func createCommandAlias(command: String, value: String) -> CommandAlias? {
        guard let commandObject = self.createObjectOfType(.CommandAlias) as? CommandAlias else {
            LOG_ERROR("Failed to create new command object.")
            return nil
        }
        commandObject.command = command.lowercaseString
        commandObject.value = value
        return commandObject
    }

    // Return the category with the specified name, or nil if there isn't one
    func loadCommandGroup(command: String) -> CommandGroup? {
        let predicate = NSPredicate(format: "command = %@", argumentArray: [command.lowercaseString])
        if let matches = self.fetchObjectsOfType(.CommandGroup, withPredicate: predicate) {
            var match: AnyObject?
            switch matches.count {
            case 0:
                return nil
            case 1:
                match = matches[0]
            default:
                LOG_DEBUG("Found multiple matches for command \(command)! Returning first match")
                match = matches[1]
            }
            if let command = match as? CommandGroup {
                return command
            }
            LOG_ERROR("Query for command group returned non-command group object \(match)")
        }
        return nil
    }

    func createCommandGroup(command: String) -> CommandGroup? {
        guard let group = self.createObjectOfType(.CommandGroup) as? CommandGroup else {
            LOG_ERROR("Failed to create new command group object.")
            return nil
        }
        group.command = command.lowercaseString
        return group
    }

}

// MARK: Base functionality
extension CoreDataManager {
    func save() {
        guard let ctx = self.managedObjectContext else {
            LOG_ERROR("Can't save database, no object context available.")
            return
        }
        ctx.performBlockAndWait {
            self.saveCtx(ctx)
        }
    }

    func setNeedsSave() {
        guard let ctx = self.managedObjectContext else {
            LOG_ERROR("Can't save database, no object context available.")
            return
        }
        ctx.performBlock {
            self.saveCtx(ctx)
        }
    }

    private func saveCtx(ctx: NSManagedObjectContext) {
        if ctx.hasChanges {
            do {
                try ctx.save()
            } catch {
                LOG_ERROR("Failed to flush data to disk (rolling back): \(error)")
                ctx.rollback()
            }
        }
    }

    func createObjectOfType(type: CoreDataObjectTypes) -> NSManagedObject? {
        var newEntity : NSManagedObject?
        if let ctx = self.managedObjectContext {
            ctx.performBlockAndWait {
                newEntity = NSEntityDescription.insertNewObjectForEntityForName(type.rawValue, inManagedObjectContext: ctx)
            }
        }
        return newEntity
    }

    func fetchObjectsOfType(type: CoreDataObjectTypes, withPredicate predicate: NSPredicate?,
                            sortedBy sortOrder: [NSSortDescriptor]? = nil,
                            fetchOffset: Int = 0, fetchLimit: Int = 0) -> [AnyObject]? {
        guard let ctx = self.managedObjectContext else {
            LOG_ERROR("Fetch failed: No managed object context.")
            return nil
        }
        var result: [AnyObject]?
        ctx.performBlockAndWait {
            let request = NSFetchRequest()
            request.entity = NSEntityDescription.entityForName(type.rawValue, inManagedObjectContext: ctx)
            request.predicate = predicate
            request.sortDescriptors = sortOrder
            request.fetchLimit = fetchLimit
            request.fetchOffset = fetchOffset
            do {
                result = try ctx.executeFetchRequest(request)
            } catch {
                LOG_ERROR("Error during fetch: \(error)")
            }
        }
        if let result = result {
            return result.count == 0 ? nil : result
        }
        return nil
    }

    func deleteObject(object: NSManagedObject) -> Bool {
        guard let ctx = self.managedObjectContext else {
            LOG_ERROR("Delete failed: No managed object context.")
            return false
        }
        ctx.performBlock {
            ctx.deleteObject(object)
        };

        return true
    }

}


// MARK: Private initialization methods
extension CoreDataManager {

    private func createPersistentStoreCoordinator() -> NSPersistentStoreCoordinator? {
        guard let dbDir = Config.databaseDirectory else {
            LOG_ERROR("Cannot configure database, no database directory configured.")
            return nil
        }
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(dbDir, withIntermediateDirectories: true, attributes:nil)
        } catch {
            LOG_ERROR("Failed to create database path at \(dbDir) - check permissions.")
            return nil
        }

        let storeUrl = NSURL(fileURLWithPath: NSString(string: dbDir).stringByAppendingPathComponent("swiftbot.sqlite"))
        guard let objectModel = self.managedObjectModel else {
            LOG_ERROR("Failed to load object model, can't open database.")
            return nil
        }
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)

        do {
            let _ = try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: [
                    NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true
            ])

        } catch {
            LOG_ERROR("Failed to open database: \(error)");
            return nil
        }
        LOG_INFO("Database opened at \(storeUrl)")
        return coordinator
    }

    private func createManagedObjectModel() -> NSManagedObjectModel? {
        let bundle = NSBundle(forClass: self.dynamicType)
        guard let model = bundle.pathForResource("SwiftBotModel", ofType: "momd") else {
            LOG_ERROR("Failed to find database model in bundle \(bundle)")
            return nil
        }
        return NSManagedObjectModel(contentsOfURL: NSURL(fileURLWithPath: model))
    }

    private func createManagedObjectContext() -> NSManagedObjectContext? {
        guard let coordinator = self.persistentStoreCoordinator else {
            LOG_ERROR("Can't create managed object context - no coordinator available.")
            return nil
        }
        let managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }
}
