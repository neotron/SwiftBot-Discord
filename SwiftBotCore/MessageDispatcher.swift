//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Handles dispatching of messages to modules that handle them.

import Foundation
import DiscordAPI

class MessageHandler {
    var prefixes : [String]? { return nil }
    var commands : [String]? { return nil }

    func handlePrefix(prefix: String, command: String, args: [String], message: Message) -> Bool {
        return false
    }

    func handleCommand(command: String, args: [String], message: Message) -> Bool {
        return false
    }
}

class MessageDispatchManager {
    private var prefixHandlers = [String:MessageHandler]() // allows prefix handling, i.e "randomcat" and "randomdog" could both go to a "random" prefix handler
    private var commandHandlers = [String:MessageHandler]() // requires either just the command, i.e "route" or command with arguments "route 32 2.3"
    weak var discord: Discord?

    func registerMessageHandler(handler: MessageHandler) {
        if let prefixes = handler.prefixes {
            for var prefix in prefixes {
                prefix = prefix.lowercaseString
                if let existingHandler = prefixHandlers[prefix] {
                    LOG_INFO("Warning: Duplicate prefix \(prefix): Replacing handler \(existingHandler) with \(handler)")
                }
                prefixHandlers[prefix] = handler
            }
            LOG_INFO("Registered \(handler) for prefixes \(prefixes)")
        }

        if let commands = handler.commands {
            for var command in commands {
                command = command.lowercaseString
                if let existingHandler = commandHandlers[command] {
                    LOG_INFO("Warning: Duplicate command \(command): Replacing handler \(existingHandler) with \(handler)")
                }
                commandHandlers[command] = handler
            }
            LOG_INFO("Registered \(handler) for commands \(commands)")
        }
    }

    func processMessage(message: MessageModel, event: MessageEventType) {
        guard let content = message.content, authorName = message.author?.username, authorId = message.author?.id, channelId = message.channelId else {
            LOG_DEBUG("Not handling message - missing content, author username or channel id");
            return
        }
        if !content.hasPrefix(Config.commandPrefix) {
            LOG_DEBUG("Message content missing required prefix.")
            return
        }
        var contentWithoutPrefix = content
        if let prefixRange = content.rangeOfString(Config.commandPrefix, options: []) {
            contentWithoutPrefix = content.substringFromIndex(prefixRange.endIndex)
        }
        var args = contentWithoutPrefix.componentsSeparatedByString(" ").filter{ $0 != "" }
        if(args.count == 0) {
            return; // No actual command, just spaces
        }

        let messageWrapper = Message(message: message, event: event, discord: discord)

        let command = args.removeAtIndex(0).lowercaseString
        if let handler = commandHandlers[command] {
            LOG_DEBUG("Found command handler for \(command)")
            if handler.handleCommand(command, args: args, message: messageWrapper) {
                LOG_DEBUG("   => handled.")
                return;
            }
        }
        for (prefix, handler) in prefixHandlers {
            if command.hasPrefix(prefix) {
                LOG_DEBUG("Found prefix handler for \(prefix)")
                if handler.handlePrefix(prefix, command: command, args: args, message: messageWrapper) {
                    LOG_DEBUG("   => handled.")
                    return;
                }
            }
        }
    }
}
