//
// Created by David Hedbor on 2/16/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation


class AuthenticatedMessageHandler: MessageHandler {
    var allowedRoles: [Role] {
        return [.admin, .owner]
    }

    final override func handlePrefix(_ prefix: String, command: String, args: [String], message: Message) -> Bool {
        if !authenticated(message) {
            return false
        }
        return handleAuthenticatedPrefix(prefix, command: command, args: args, message: message)
    }

    final override func handleCommand(_ command: String, args: [String], message: Message) -> Bool {
        if !authenticated(message) {
            return false
        }
        return handleAuthenticatedCommand(command, args: args, message: message)
    }

    final override func handleAnything(_ command: String, args: [String], message: Message) -> Bool {
        if !authenticated(message) {
            return false
        }
        return handleAuthenticatedAnything(command, args: args, message: message)
    }

    func handleAuthenticatedPrefix(_ prefix: String, command: String, args: [String], message: Message) -> Bool {
        return false
    }

    func handleAuthenticatedCommand(_ command: String, args: [String], message: Message) -> Bool {
        return false
    }

    func handleAuthenticatedAnything(_ command: String, args: [String], message: Message) -> Bool {
        return false
    }

    final fileprivate func authenticated(_ message: Message) -> Bool {
        let isAuth = {
            (Void) -> Bool in
            let roles = CoreDataManager.instance.fetchRolesForId(message.author!.id!)
            for role in allowedRoles {
                if roles.contains(role) {
                    return true;
                }
            }
            return false
        }()
        if (!isAuth) {
            message.replyToChannel("@\(message.author!.username!): I can't let you do that.")
        }
        return isAuth
    }

}

class MessageHandler: NSObject {
    var prefixes: [MessageCommand]? {
        return nil
    }
    var commands: [MessageCommand]? {
        return nil
    }
    var commandGroup: String? {
        return ""
    }
    var canMatchAnything: Bool {
        return false
    }

    func handlePrefix(_ prefix: String, command: String, args: [String], message: Message) -> Bool {
        return false
    }

    func handleCommand(_ command: String, args: [String], message: Message) -> Bool {
        return false
    }

    func handleAnything(_ command: String, args: [String], message: Message) -> Bool {
        return false
    }
}
