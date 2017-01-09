//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Handles dispatching of messages to modules that handle them.

import Foundation
import SwiftDiscord

typealias MessageCommand = (c:String, h:String?)

struct CommandFlags: OptionSet {
    let rawValue: Int
    static let None = CommandFlags(rawValue: 0)
    static let Verbose = CommandFlags(rawValue: 1 << 0)
    static let Help = CommandFlags(rawValue: 1 << 1)
    static let Here = CommandFlags(rawValue: 1 << 2)
}

class MessageDispatchManager: MessageHandler {
    fileprivate var prefixHandlers = [String: [MessageHandler]]()
    // allows prefix handling, i.e "randomcat" and "randomdog" could both go to a "random" prefix handler
    fileprivate var commandHandlers = [String: [MessageHandler]]()
    // requires either just the command, i.e "route" or command with arguments "route 32 2.3"
    fileprivate var anythingHandlers = [MessageHandler]()
    // These are called, in order, if nothing else matches. The matching logic can be whatever, such as substring matches.
    fileprivate var commandHelp = [String: [String: [String]]]()
    weak var discord: Discord?

    override init() {
        super.init()
        self.registerMessageHandlers()
    }

    override var commands: [MessageCommand]? {
        return [("help", nil)]
    }

    override func handleCommand(_ command: String, args: [String], message: Message) -> Bool {

        for group in commandHelp.keys.sorted() {
            var output = [String]()
            if group != "" {
                output.append("**\(group)**")
            } else {
                output.append("**SwiftBot Commands**:")
            }
            for command in commandHelp[group]!.keys.sorted() {
                output.append(commandHelp[group]![command]!.joined(separator: "\n"))
            }
            if message.flags.contains(.Here) {
                message.replyToChannel(output.joined(separator: "\n"));
            } else {
                message.replyToSender(output.joined(separator: "\n"));
            }
        }
        return true
    }

    fileprivate func registerMessageHandlers() {
        registerMessageHandler(self) // this registers the help command
        registerMessageHandler(PingMessageHandler())
        registerMessageHandler(RandomAnimalsMessageHandler())
        registerMessageHandler(ScienceMessageHandler())
        registerMessageHandler(IdentifierMessageHandler())
        registerMessageHandler(CustomCommandMessageHandler())
        registerMessageHandler(CustomCommandImportMessageHandler())
        registerMessageHandler(UserRoleMessageHandler())
        registerMessageHandler(DistantWorldsWaypoints())
        registerMessageHandler(EDSMMessageHandler())
    }


    func registerMessageHandler(_ handler: MessageHandler) {
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

    fileprivate func addHandlerForCommand(_ command: MessageCommand, inDict dict: inout [String:[MessageHandler]], handler: MessageHandler) {
        let commandStr = command.c.lowercased()
        if let helpString = command.h, let group = handler.commandGroup {
            if commandHelp[group] == nil {
                commandHelp[group] = [commandStr: []]
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

    func parseCommandFlags(_ args: [String]) -> CommandFlags {
        var flags = CommandFlags.None
        let argSet = Set(args)
        if argSet.contains("-v") || argSet.contains("--verbose") || argSet.contains("verbose") {
            flags.insert(.Verbose)
        }
        if argSet.contains("-h") || argSet.contains("help") {
            flags.insert(.Help)
        }
        if argSet.contains("here") || argSet.contains("--here") {
            flags.insert(.Here)
        }
        return flags
    }

    func processMessage(_ message: DiscordMessage, event: MessageEventType) {
        let content = message.content

        if !content.hasPrefix(Config.commandPrefix) {
            LOG_DEBUG("Message content missing required prefix.")
            return
        }
        var contentWithoutPrefix = content
        if let prefixRange = content.range(of: Config.commandPrefix, options: []) {
            contentWithoutPrefix = content.substring(from: prefixRange.upperBound)
        }
        var args = contentWithoutPrefix.components(separatedBy: " ")
        let flags = parseCommandFlags(args)
        let messageWrapper = Message(message: message, event: event, discord: discord, flags: flags)
        messageWrapper.rawArgs = args
        args = args.filter {
            $0 != ""
        }
        if args.count == 0 {
            LOG_DEBUG("No command, just a prefix!")
            return
        }
        let command = args.remove(at: 0).lowercased()

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
