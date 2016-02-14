//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Handles dispatching of messages to modules that handle them.

import Foundation
import DiscordAPI

protocol MessageHandler : class {
    var prefixes : [String]? { get }
    var commands : [String]? { get }

    func handlePrefix(prefix: String, command: String, args: [String], message: MessageModel, event: MessageEventType, completeCallback: (responseMessage: String?, privateMessage: Bool?)->(Void)) -> Bool
    func handleCommand(command: String, args: [String], message: MessageModel, event: MessageEventType, completeCallback: (responseMessage: String?, privateMessage: Bool?)->(Void)) -> Bool
}

class MessageDispatchManager {
    private let config: Config
    private var prefixHandlers = [String:MessageHandler]() // allows prefix handling, i.e "randomcat" and "randomdog" could both go to a "random" prefix handler
    private var commandHandlers = [String:MessageHandler]() // requires either just the command, i.e "route" or command with arguments "route 32 2.3"
    weak var discord: Discord?

    init(withConfig config: Config) {
        self.config = config
    }

    func registerMessageHandler(handler: MessageHandler) {
        if let prefixes = handler.prefixes {
            for prefix in prefixes {
                if let existingHandler = prefixHandlers[prefix] {
                    LOG_INFO("Warning: Duplicate prefix \(prefix): Replacing handler \(existingHandler) with \(handler)")
                }
                prefixHandlers[prefix] = handler
            }
            LOG_INFO("Registered \(handler) for prefixes \(prefixes)")
        }

        if let commands = handler.commands {
            for command in commands {
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
        if !content.hasPrefix(config.commandPrefix) {
            LOG_DEBUG("Message content missing required prefix.")
            return
        }
        var contentWithoutPrefix = content
        if let prefixRange = content.rangeOfString(config.commandPrefix, options: []) {
            contentWithoutPrefix = content.substringFromIndex(prefixRange.endIndex)
        }
        let messageHandler = { (responseMessage: String?, privateMessage: Bool?) in
            if let message = responseMessage {
                // we have a response!
                var responseChannel = privateMessage != nil && privateMessage! ? authorId : channelId
                self.discord?.sendMessage(message, channel: responseChannel, mentions: [])
            }
        }

        var args = contentWithoutPrefix.componentsSeparatedByString(" ")
        let command = args.removeAtIndex(0)
        if let handler = commandHandlers[command] {
            LOG_DEBUG("Found command handler for \(command)")
            if handler.handleCommand(command, args: args, message: message, event: event, completeCallback: messageHandler) {
                LOG_DEBUG("   => handled.")
                return;
            }
        }
        for (prefix, handler) in prefixHandlers {
            if contentWithoutPrefix.hasPrefix(prefix) {
                LOG_DEBUG("Found prefix handler for \(prefix)")
                if handler.handlePrefix(prefix, command: command, args: args, message: message, event: event, completeCallback: messageHandler) {
                    LOG_DEBUG("   => handled.")
                    return;
                }
            }
        }
    }
}
