//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Handles dispatching of messages to modules that handle them.

import Foundation
import DiscordAPI
typealias MessageCommand = (c: String, h: String?)

class MessageHandler {
    var prefixes : [MessageCommand]? { return nil }
    var commands : [MessageCommand]? { return nil }

    func handlePrefix(prefix: String, command: String, args: [String], message: Message) -> Bool {
        return false
    }

    func handleCommand(command: String, args: [String], message: Message) -> Bool {
        return false
    }
}

class MessageDispatchManager {
    private var prefixHandlers  = [String:[MessageHandler]]() // allows prefix handling, i.e "randomcat" and "randomdog" could both go to a "random" prefix handler
    private var commandHandlers = [String:[MessageHandler]]() // requires either just the command, i.e "route" or command with arguments "route 32 2.3"
    private var help = [String:[String]]()
    weak var discord: Discord?

    func registerMessageHandler(handler: MessageHandler) {
        if let prefixes = handler.prefixes {
            for var prefix in prefixes {
                addHandlerForCommand(prefix, inDict: &prefixHandlers, handler: handler)
            }
        }

        if let commands = handler.commands {
            for var command in commands {
                addHandlerForCommand(command, inDict: &commandHandlers, handler: handler)
            }
        }
    }

    private func addHandlerForCommand(command: MessageCommand, inout inDict dict:[String:[MessageHandler]], handler: MessageHandler) {
        let commandStr = command.c.lowercaseString
        if let helpString = command.h {
            if help[commandStr] == nil {
                help[commandStr] = [String]()
            }
            help[commandStr]?.append("\t**\(Config.commandPrefix)\(commandStr)**: \(helpString)")
        }
        if dict[commandStr] == nil {
            dict[commandStr] = [MessageHandler]()
        }
        dict[commandStr]?.append(handler)
        LOG_INFO("Registered \(handler) for \(commandStr)")
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

        if command == "help" {
            printHelp(messageWrapper)
            return
        }

        if let handlers = commandHandlers[command] {
            LOG_DEBUG("Found command handler for \(command)")
            for handler in handlers {
                if handler.handleCommand(command, args: args, message: messageWrapper) {
                    LOG_DEBUG("   => handled.")
                    return;
                }
            }
        }
        for (prefix, handlers) in prefixHandlers {
            if command.hasPrefix(prefix) {
                LOG_DEBUG("Found prefix handler for \(prefix)")
                for handler in handlers {
                    if handler.handlePrefix(prefix, command: command, args: args, message: messageWrapper) {
                        LOG_DEBUG("   => handled.")
                        return;
                    }
                }
            }
        }
    }

    func printHelp(message: Message) {
        var output = ["Bot Commands:"]

        for command in help.keys.sort() {
            output.append(help[command]!.joinWithSeparator("\n"))
        }
        message.replyToChannel(output.joinWithSeparator("\n"));
    }
}
