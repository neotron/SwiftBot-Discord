//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Handles dispatching of messages to modules that handle them.

import Foundation
import DiscordAPI
typealias MessageCommand = (c: String, h: String?)

class MessageDispatchManager : MessageHandler {
    private var prefixHandlers  = [String:[MessageHandler]]() // allows prefix handling, i.e "randomcat" and "randomdog" could both go to a "random" prefix handler
    private var commandHandlers = [String:[MessageHandler]]() // requires either just the command, i.e "route" or command with arguments "route 32 2.3"
    private var anythingHandlers = [MessageHandler]() // These are called, in order, if nothing else matches. The matching logic can be whatever, such as substring matches.
    private var commandHelp = [String:[String:[String]]]()
    weak var discord: Discord?

    override init() {
        super.init()
        self.registerMessageHandlers()
    }

    override var commands: [MessageCommand]? {
        return [("help", nil)]
    }

    override func handleCommand(command: String, args: [String], message: Message) -> Bool {
        var output = ["**SwiftBot Commands**:"]

        for group in commandHelp.keys.sort() {
            if group != "" {
                output.append("\n**\(group)**")
            }
            for command in commandHelp[group]!.keys.sort() {
                output.append(commandHelp[group]![command]!.joinWithSeparator("\n"))
            }
        }
        if args.count > 0 && args[0] == "here" {
            message.replyToChannel(output.joinWithSeparator("\n"));
        } else {
            message.replyToSender(output.joinWithSeparator("\n"));
        }
        return true
    }

    private func registerMessageHandlers() {
        registerMessageHandler(self) // this registers the help command
        registerMessageHandler(PingMessageHandler())
        registerMessageHandler(RandomAnimalsMessageHandler())
        registerMessageHandler(ScienceMessageHandler())
        registerMessageHandler(IdentifierMessageHandler())
        registerMessageHandler(CustomCommandMessageHandler())
        registerMessageHandler(CustomCommandImportMessageHandler())
        registerMessageHandler(UserRoleMessageHandler())
    }


    func registerMessageHandler(handler: MessageHandler) {
        if let prefixes = handler.prefixes {
            for prefix in prefixes {
                addHandlerForCommand(prefix, inDict: &prefixHandlers, handler: handler)
            }
        }

        if let commands = handler.commands {
            for command in commands {
                addHandlerForCommand(command, inDict: &commandHandlers, handler: handler)
            }
        }

        if handler.canMatchAnything {
            anythingHandlers.append(handler)
        }
    }

    private func addHandlerForCommand(command: MessageCommand, inout inDict dict:[String:[MessageHandler]], handler: MessageHandler) {
        let commandStr = command.c.lowercaseString
        if let helpString = command.h, group = handler.commandGroup {
            if commandHelp[group] == nil {
                commandHelp[group] = [commandStr:[]]
            } else if commandHelp[group]![commandStr] == nil {
                commandHelp[group]![commandStr] = [String]()
            }
            commandHelp[group]?[commandStr]?.append("\t**\(Config.commandPrefix)\(commandStr)**: \(helpString)")
        }
        if dict[commandStr] == nil {
            dict[commandStr] = [MessageHandler]()
        }
        dict[commandStr]?.append(handler)
        LOG_INFO("Registered \(handler) for \(commandStr)")
    }

    func processMessage(message: MessageModel, event: MessageEventType) {
        guard let content = message.content, _ = message.author?.username, _ = message.author?.id, _ = message.channelId else {
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
        var args = contentWithoutPrefix.componentsSeparatedByString(" ")
        let messageWrapper = Message(message: message, event: event, discord: discord)
        messageWrapper.rawArgs = args
        args = args.filter { $0 != "" }
        let command = args.removeAtIndex(0).lowercaseString

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

        for handler in anythingHandlers {
            LOG_DEBUG("Trying anything handler \(handler)...")
            if handler.handleAnything(command, args: args, message: messageWrapper) {
                LOG_DEBUG("    => handled")
                return
            }

        }
    }
}
