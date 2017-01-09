//
// Created by David Hedbor on 2/15/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Singleton managing access to the database
//

import Foundation
import SwiftDiscord
import SQLiteStORM
import StORM

// for now

class Database {
    static let instance = Database()

    fileprivate var setupComplete = false
    func isSetupAndWorking() -> Bool {
        return setupComplete
    }
}


// MARK: UserRole support

extension Database {


    func fetchRolesForId(_ id: String) -> Set<Role> {
        var roles = Set<Role>()
        let user = UserRole()
        do {
            try user.find(["userId": id])
            for userRole in user.rows() {
                roles.insert(userRole.role)
            }
        } catch {
            LOG_ERROR("Failed to load roles for \(id)")
        }
        return roles
    }

    func addRoleForUserId(_ id: String, role: Role) -> Bool {
        let roles = self.fetchRolesForId(id)
        if roles.contains(role) || roles.contains(.owner) {
            return false
        }
        return self.createUserRole(id, role: role)
    }

    func removeRoleForUser(_ id: String, role: Role) -> Bool {
        let userRole = UserRole()
        do {
            try userRole.find(["userId": id, "roleId": "\(role.rawValue)"])
            guard userRole.id > 0 else {
                return false
            }
            try userRole.delete()
            return true
        } catch {
            LOG_ERROR("Failed to delete user role.")
            return false;
        }
    }


    func updateOwnerRolesFromConfig() {
        LOG_INFO("Configured owner ids: \(Config.ownerIds)")
        var adminIds = Config.ownerIds
        let userRole = UserRole()
        do {
            try userRole.find(["roleId": "\(Role.owner.rawValue)"])
            // Existing admins
            for admin in userRole.rows() {
                if !adminIds.contains(admin.userId) {
                    LOG_DEBUG("Deleting old owner: \(admin.userId)")
                    _ = self.deleteObject(admin)
                }
                adminIds.remove(admin.userId)
            }
            for id in adminIds {
                _ = self.createUserRole(id, role: Role.owner)
            }
        } catch {
            LOG_ERROR("Failed to update owners: \(error)")
        }
    }

    fileprivate func createUserRole(_ id: String, role: Role) -> Bool {
        let admin = UserRole()
        admin.userId = id
        admin.role = role
        if(save(admin)) {
            LOG_DEBUG("Added new user role mapping: \(id) -> \(role)")
            return true
        }
        return false
    }

    fileprivate func fetchUserRoleForId(_ id: String, role: Role) -> UserRole? {
        let userRole = UserRole()
        do {
            try userRole.find(["userId": id, "role": "\(role.rawValue)"])
            if userRole.id > 0 {
                return userRole
            }
        } catch {
            LOG_ERROR("Failed to fetch userRole: \(error)")
        }
        return nil
    }
}

// MARK: Custom commands helper functions

extension Database {
    // Return the command with the specified name, or nil if there isn't one
    func loadCommandAlias(_ command: String) -> CommandAlias? {
        let cmd = CommandAlias()
        do {
            try cmd.find(["command": command])
            if cmd.id > 0 {
                return cmd
            }
        } catch {
            LOG_ERROR("Failed to load command: \(error)")
        }
        return nil
    }

    func createCommandAlias(_ command: String, value: String) -> CommandAlias? {
        let commandObject = CommandAlias()
        commandObject.command = command.lowercased()
        commandObject.value = value
        return commandObject
    }

    // Return the category with the specified name, or nil if there isn't one
    func loadCommandGroup(_ command: String) -> CommandGroup? {
        let cmd = CommandGroup()
        do {
            try cmd.find(["command": command])
            if cmd.id > 0 {
                return cmd
            }
        } catch {
            LOG_ERROR("Failed to load command: \(error)")
        }
        return nil
    }

    func createCommandGroup(_ command: String) -> CommandGroup? {
        let group = CommandGroup()
        group.command = command.lowercased()
        return group
    }

}

// MARK: Base functionality

extension Database {
    func save(_ object: SQLiteStORM) -> Bool {
        do {
            try object.save()
            return true
        } catch {
            LOG_ERROR("Failed to save object: \(error)")
            return false
        }
    }

    func deleteObject(_ object: SQLiteStORM) -> Bool {
        do {
            try object.delete()
            return true
        } catch {
            return false
        }
    }

}


// MARK: Private initialization methods

extension Database {

    func openDatabase() {
        if let path = Config.databaseDirectory {
            SQLiteConnector.db = "\(path)/swiftbot.sqlite"

            let userRole = UserRole()
            let commandGroup = CommandGroup()
            let commandAlias = CommandAlias()
            do {
                try userRole.setup()
                try commandGroup.setup()
                try commandAlias.setup()
                setupComplete = true
            } catch {
                setupComplete = false
                LOG_ERROR("Failed to setup database: \(error)")
            }
        }
    }
}
