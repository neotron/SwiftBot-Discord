//
// Created by David Hedbor on 2/14/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import SwiftDiscord

class IdentifierMessageHandler: MessageHandler {
    override var commands: [MessageCommand]? {
        return [
                ("id", "Return Discord ID for the user, or all @mentioned users")
        ]
    }

    override func handleCommand(_ command: String, args: [String], message: Message) -> Bool {
        var identities = [String]()
        if args.count == 0 {
            // Identify the caller
            if let id = message.author?.id, let name = message.author?.username {
                identities.append("\(name) has id \(id)")
            }
        } else {
            if let mentions = message.mentions {
                for author in mentions {
                    if let id = author.id, let name = author.username {
                        identities.append("\(name) has id \(id)")
                    }
                }
            }
        }
        if identities.count > 0 {
            message.replyToChannel("Identities:\n\t\(identities.joined(separator: "\n\t"))");
        } else {
            message.replyToChannel("No one was identified")
        }
        return true
    }

}
