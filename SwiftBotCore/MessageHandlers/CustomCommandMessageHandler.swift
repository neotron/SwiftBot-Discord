//
// Created by David Hedbor on 2/15/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Handles aliasing of commands and such

import Foundation
import DiscordAPI

class CustomCommandMessageHandler : MessageHandler {
    override var commandGroup: String? {
        return "Custom Command Management"
    }
    override var canMatchAnything: Bool {
        return true
    }

    override var commands: [MessageCommand]? {
        return [
                (Command.AddCommand.rawValue,         "Add new command. Arguments: *<command> <text>*"),
                (Command.RemoveCommand.rawValue,      "Remove existing command. Arguments: *<command>*"),
                (Command.EditCommand.rawValue,        "Replace text for existing command. Arguments: *<command> <new text>*"),
                (Command.SetHelpText.rawValue,            "Set (or remove) a help string for an existing command or category. Arguments: *<command or category> [help text]*"),
                (Command.AddToCategory.rawValue,      "Add an existing command to a category. Category will be created if it doesn't exist. Arguments: *<category> <command>*"),
                (Command.RemoveFromCategory.rawValue, "Remove a command from a category. Arguments: *<category> <command>*"),
                (Command.DeleteCategory.rawValue,     "Delete an existing category. Commands in the category will not be removed. Arguments: *<category>*"),
        ];
    }

    override func handleCommand(command: String, args: [String], message: Message) -> Bool {
        guard let cmd = Command(rawValue: command) else {
            LOG_ERROR("Got sent invalid command: \(command) - odd")
            return false
        }
        switch(cmd) {
        case .AddCommand:
            addCommand(args, message: message)
        case .RemoveCommand:
            removeCommand(args, message: message)
        case .EditCommand:
            editCommand(args, message: message)
        case .SetHelpText:
            addHelp(args, message: message)
        case .AddToCategory:
            break
        case .RemoveFromCategory:
            break
        case .DeleteCategory:
            break;
        }
        return true
    }

    override func handleAnything(command: String, args: [String], message: Message) -> Bool {
        let cdm = CoreDataManager.instance
        if let commandObject = cdm.loadCommand(command), value = commandObject.value {
            if args.count == 1 && (args[0] == "help" || args[0] == "-h") {
                if let help = commandObject.help {
                    message.replyToChannel("**\(Config.commandPrefix)\(commandObject.command!)**: \(help)")
                } else {
                    message.replyToChannel("**\(Config.commandPrefix)\(commandObject.command!)**: No help available.")
                }
            } else {
                message.replyToChannel(value)
            }
            return true
        }
        return false
    }


}

// MARK: Add / Edit / Remove commands
extension CustomCommandMessageHandler {

    func getCommandText(command: String, message: Message) -> String? {
        guard var commandValueArgs = message.rawArgs else {
            message.replyToChannel("Missing command alias text.")
            return nil
        }
        while commandValueArgs.count > 0 && commandValueArgs.removeFirst() != command {
            // No-op
        }
        return commandValueArgs.joinWithSeparator(" ")
    }

    func addCommand(args: [String], message: Message) {
        if args.count < 2 {
            message.replyToChannel("Invalid syntax. Expected: <command> <new text>")
            return
        }
        let cdm = CoreDataManager.instance
        if let existingCommand = cdm.loadCommand(args[0]) {
            message.replyToChannel("Command *\(existingCommand.command!)* already exist. Use *\(Config.commandPrefix)\(Command.EditCommand.rawValue)* instead.")
            return
        }

        guard let commandText = getCommandText(args[0], message: message), command = cdm.createCommand(args[0], value: commandText) else {
            LOG_ERROR("Command was not created.")
            message.replyToChannel("Internal error. Unable to create command alias.")
            return
        }
        cdm.setNeedsSave()
        message.replyToChannel("Command alias for *\(command.command!)* created successfully.")
    }

    func editCommand(args: [String], message: Message) {
        if args.count < 2 {
            message.replyToChannel("Invalid syntax. Expected: <command> <new text>")
            return
        }
        let cdm = CoreDataManager.instance
        guard let existingCommand = cdm.loadCommand(args[0]) else {
            message.replyToChannel("Command *\(args[0])* doesn't exist. Use *\(Config.commandPrefix)\(Command.AddCommand.rawValue)* instead.")
            return
        }

        guard let commandText = getCommandText(args[0], message: message) else {
            message.replyToChannel("Missing command text, check your arguments.");
            return
        }

        existingCommand.value = commandText
        cdm.setNeedsSave()
        message.replyToChannel("Command *\(existingCommand.command!)* updated with new text.")
    }

    func removeCommand(args: [String], message: Message) {
        if args.count < 1 {
            message.replyToChannel("Invalid syntax. Expected: <command>")
            return
        }
        let cdm = CoreDataManager.instance
        guard let existingCommand = cdm.loadCommand(args[0]) else {
            message.replyToChannel("Command *\(args[0])* doesn't exist.")
            return
        }
        if cdm.deleteObject(existingCommand) {
            message.replyToChannel("Command *\(args[0])* removed.")
            cdm.setNeedsSave()
        } else {
            message.replyToChannel("Command *\(args[0])* was not removed due to internal error.")
        }
    }

    func addHelp(args: [String], message: Message) {
        if args.count < 2 {
            message.replyToChannel("Invalid syntax. Expected: <command> <help text>")
            return
        }

        let cdm = CoreDataManager.instance
        guard let existingCommand = cdm.loadCommand(args[0]) else {
            message.replyToChannel("Command *\(args[0])* doesn't exist.")
            return
        }

        existingCommand.help = getCommandText(args[0], message: message)

        cdm.setNeedsSave()
        message.replyToChannel("Command *\(existingCommand.command!)* updated with help text.")
    }
}


// MARK: Enum for commands
extension CustomCommandMessageHandler {
    private enum Command: String {
        case AddCommand = "addcmd",
             RemoveCommand = "rmcmd",
             EditCommand = "editcmd",
             SetHelpText = "sethelp",
             AddToCategory = "addtocat",
             RemoveFromCategory = "rmfromcat",
             DeleteCategory = "delcat"
    }
}
