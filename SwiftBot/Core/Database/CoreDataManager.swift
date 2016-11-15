//
// Created by David Hedbor on 2/15/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Singleton managing access to the database
//

import Foundation
import CoreData
import DiscordAPI

class CoreDataManager: NSObject {
    static let instance = CoreDataManager()

    lazy fileprivate var persistentStoreCoordinator = CoreDataManager.instance.createPersistentStoreCoordinator()
    lazy fileprivate var managedObjectModel = CoreDataManager.instance.createManagedObjectModel()
    lazy fileprivate var managedObjectContext = CoreDataManager.instance.createManagedObjectContext()

    override init() {
        super.init()
    }

    func isSetupAndWorking() -> Bool {
        return self.persistentStoreCoordinator != nil
    }
}


// MARK: UserRole support

extension CoreDataManager {


    func fetchRolesForId(_ id: String) -> Set<Role> {
        var roles = Set<Role>()
        if let ctx = self.managedObjectContext {
            ctx.performAndWait {
                let predicate = NSPredicate(format: "id = %@", id)
                if let userRoles = self.fetchObjectsOfType(.UserRole, withPredicate: predicate) as? [UserRole] {
                    for userRole in userRoles {
                        roles.insert(userRole.role)
                    }
                }
            }
        }
        return roles
    }

    func addRoleForUserId(_ id: String, role: Role) -> Bool {
        let roles = self.fetchRolesForId(id)
        if roles.contains(role) || roles.contains(.owner) {
            return false
        }
        if let ctx = self.managedObjectContext {
            ctx.perform {
                self.createUserRole(id, role: role)
                self.saveCtx(ctx)
            }
            return true
        }
        return false;
    }

    func removeRoleForUser(_ id: String, role: Role) -> Bool {
        let roles = self.fetchRolesForId(id)
        if !roles.contains(role) || roles.contains(.owner) {
            return false
        }
        if let ctx = self.managedObjectContext {
            ctx.perform {
                if let userRole = self.fetchUserRoleForId(id, role: role) {
                    ctx.delete(userRole)
                    self.saveCtx(ctx)
                }
            }
            return true
        }
        return false;

    }


    func updateOwnerRolesFromConfig() {
        if let ctx = self.managedObjectContext {
            ctx.perform {
                LOG_INFO("Configured owner ids: \(Config.ownerIds)")
                var adminIds = Config.ownerIds
                let predicate = NSPredicate(format: "role = %d", Role.owner.rawValue)
                if let admins = self.fetchObjectsOfType(.UserRole, withPredicate: predicate) as? [UserRole] {
                    // Existing admins
                    for admin in admins {
                        if !adminIds.contains(admin.id) {
                            LOG_DEBUG("Deleting old owner: \(admin.id)")
                            self.deleteObject(admin)
                        }
                        adminIds.remove(admin.id)
                    }
                }
                for id in adminIds {
                    self.createUserRole(id, role: Role.owner)
                }
            }
            self.saveCtx(ctx)
        }
    }

    fileprivate func createUserRole(_ id: String, role: Role) {
        if let admin = self.createObjectOfType(.UserRole) as? UserRole {
            admin.id = id
            admin.role = role
            LOG_DEBUG("Added new user role mapping: \(id) -> \(role)")
        }

    }

    fileprivate func fetchUserRoleForId(_ id: String, role: Role) -> UserRole? {
        var userRole: UserRole?
        if let ctx = self.managedObjectContext {
            ctx.performAndWait {
                let predicate = NSPredicate(format: "id = %@ AND role = %d", id, role.rawValue)
                if let userRoles = self.fetchObjectsOfType(.UserRole, withPredicate: predicate) as? [UserRole] {
                    userRole = userRoles.first
                }
            }
        }
        return userRole
    }
}

// MARK: Custom commands helper functions

extension CoreDataManager {
    // Return the command with the specified name, or nil if there isn't one
    func loadCommandAlias(_ command: String) -> CommandAlias? {
        let predicate = NSPredicate(format: "command = %@", argumentArray: [command.lowercased()])
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

    func createCommandAlias(_ command: String, value: String) -> CommandAlias? {
        guard let commandObject = self.createObjectOfType(.CommandAlias) as? CommandAlias else {
            LOG_ERROR("Failed to create new command object.")
            return nil
        }
        commandObject.command = command.lowercased()
        commandObject.value = value
        return commandObject
    }

    // Return the category with the specified name, or nil if there isn't one
    func loadCommandGroup(_ command: String) -> CommandGroup? {
        let predicate = NSPredicate(format: "command = %@", argumentArray: [command.lowercased()])
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

    func createCommandGroup(_ command: String) -> CommandGroup? {
        guard let group = self.createObjectOfType(.CommandGroup) as? CommandGroup else {
            LOG_ERROR("Failed to create new command group object.")
            return nil
        }
        group.command = command.lowercased()
        return group
    }

}

// MARK: Base functionality

extension CoreDataManager {
    func save(_ synchronous: Bool = false) {
        guard let ctx = self.managedObjectContext else {
            LOG_ERROR("Can't save database, no object context available.")
            return
        }
        if synchronous {
            ctx.performAndWait {
                self.saveCtx(ctx)
            }
        } else {
            ctx.perform {
                self.saveCtx(ctx)
            }
        }
    }

    fileprivate func saveCtx(_ ctx: NSManagedObjectContext) {
        if ctx.hasChanges {
            do {
                try ctx.save()
            } catch {
                LOG_ERROR("Failed to flush data to disk (rolling back): \(error)")
                ctx.rollback()
            }
        }
    }

    func createObjectOfType(_ type: CoreDataObjectTypes) -> NSManagedObject? {
        var newEntity: NSManagedObject?
        if let ctx = self.managedObjectContext {
            ctx.performAndWait {
                newEntity = NSEntityDescription.insertNewObject(forEntityName: type.rawValue, into: ctx)
            }
        }
        return newEntity
    }

    func fetchObjectsOfType(_ type: CoreDataObjectTypes, withPredicate predicate: NSPredicate?,
                            sortedBy sortOrder: [NSSortDescriptor]? = nil,
                            fetchOffset: Int = 0, fetchLimit: Int = 0) -> [AnyObject]? {
        guard let ctx = self.managedObjectContext else {
            LOG_ERROR("Fetch failed: No managed object context.")
            return nil
        }
        var result: [AnyObject]?
        ctx.performAndWait {
            let request = NSFetchRequest<NSFetchRequestResult>()
            request.entity = NSEntityDescription.entity(forEntityName: type.rawValue, in: ctx)
            request.predicate = predicate
            request.sortDescriptors = sortOrder
            request.fetchLimit = fetchLimit
            request.fetchOffset = fetchOffset
            do {
                result = try ctx.fetch(request)
            } catch {
                LOG_ERROR("Error during fetch: \(error)")
            }
        }
        if let result = result {
            return result.count == 0 ? nil : result
        }
        return nil
    }

    func deleteObject(_ object: NSManagedObject) -> Bool {
        guard let ctx = self.managedObjectContext else {
            LOG_ERROR("Delete failed: No managed object context.")
            return false
        }
        ctx.perform {
            ctx.delete(object)
        };

        return true
    }

}


// MARK: Private initialization methods

extension CoreDataManager {

    fileprivate func createPersistentStoreCoordinator() -> NSPersistentStoreCoordinator? {
        guard let dbDir = Config.databaseDirectory else {
            LOG_ERROR("Cannot configure database, no database directory configured.")
            return nil
        }
        do {
            try FileManager.default.createDirectory(atPath: dbDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            LOG_ERROR("Failed to create database path at \(dbDir) - check permissions.")
            return nil
        }

        let storeUrl = URL(fileURLWithPath: NSString(string: dbDir).appendingPathComponent("swiftbot.sqlite"))
        guard let objectModel = self.managedObjectModel else {
            LOG_ERROR("Failed to load object model, can't open database.")
            return nil
        }
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)

        do {
            let _ = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: [
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

    fileprivate func createManagedObjectModel() -> NSManagedObjectModel? {
        let bundle = Bundle(for: type(of: self))
        guard let model = bundle.path(forResource: "SwiftBotModel", ofType: "momd") else {
            LOG_ERROR("Failed to find database model in bundle \(bundle)")
            return nil
        }
        return NSManagedObjectModel(contentsOf: URL(fileURLWithPath: model))
    }

    fileprivate func createManagedObjectContext() -> NSManagedObjectContext? {
        guard let coordinator = self.persistentStoreCoordinator else {
            LOG_ERROR("Can't create managed object context - no coordinator available.")
            return nil
        }
        let managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }

    func reopenDatabase() {
        self.persistentStoreCoordinator = self.createPersistentStoreCoordinator()
        self.managedObjectContext = self.createManagedObjectContext()
    }
}
