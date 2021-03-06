//
// Created by David Hedbor on 2/16/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI

class UserRoleMessageHandler: AuthenticatedMessageHandler {
    override var commands: [MessageCommand]? {
        return [
                ("setadm", "Add administrator role to users. Syntax: \(Config.commandPrefix)setadm @User1 [@User2, ...]"),
                ("rmadm", "Remove administrator role from users. Syntax: \(Config.commandPrefix)rmadm @User1 [@User2, ...]"),
        ]
    }
    override var commandGroup: String? {
        return "User role administration"
    }

    override func handleAuthenticatedCommand(_ command: String, args: [String], message: Message) -> Bool {
        switch (command) {
        case "setadm":
            addAdminRights(message)
        case "rmadm":
            removeAdminRights(message)
        default:
            return false
        }
        return true
    }

    fileprivate func mentionedUserIds(_ message: Message) -> [String]? {
        guard let userIds = {
            (Void) -> [String]? in
            guard let mentions = message.mentions  else {
                return nil
            }
            var userIds = [String]()
            for mention in mentions {
                if let id = mention.id {
                    userIds.append(id)
                }
            }
            return userIds.count > 0 ? userIds : nil
        }() else {
            message.replyToChannel("Missing users on the mention line!")
            return nil
        }
        return userIds
    }

    fileprivate func addAdminRights(_ message: Message) {
        guard let userIds = mentionedUserIds(message) else {
            return
        }
        var numAdded = 0
        let cdm = CoreDataManager.instance
        for id in userIds {
            if cdm.addRoleForUserId(id, role: .admin) {
                numAdded += 1
            }
        }
        message.replyToChannel("Added admin role to \(numAdded) users.")
    }

    fileprivate func removeAdminRights(_ message: Message) {
        guard let userIds = mentionedUserIds(message) else {
            return
        }
        var numRemoved = 0
        let cdm = CoreDataManager.instance
        for id in userIds {
            if cdm.removeRoleForUser(id, role: .admin) {
                numRemoved += 1
            }
        }
        message.replyToChannel("Removed admin role from \(numRemoved) users.")
    }

}
