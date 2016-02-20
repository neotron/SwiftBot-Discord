//
// Created by David Hedbor on 2/15/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Handles aliasing of commands and such

import Foundation
import DiscordAPI

class CustomCommandMessageHandler: MessageHandler {
    internal static let CustomCommandGroup = "Custom Command Management"

    override var commandGroup: String? {
        return CustomCommandMessageHandler.CustomCommandGroup
    }
    override var canMatchAnything: Bool {
        return true
    }

    override var commands: [MessageCommand]? {
        return [
                (Command.AddCommand.rawValue, "Add new command. Arguments: *<command> <text>*"),
                (Command.RemoveCommand.rawValue, "Remove existing command. Arguments: *<command>*"),
                (Command.EditCommand.rawValue, "Replace text for existing command. Arguments: *<command> <new text>*"),
                (Command.SetHelpText.rawValue, "Set (or remove) a help string for an existing command or category. Arguments: *<command or category> [help text]*"),
                (Command.AddToCategory.rawValue, "Add an existing command to a category. Category will be created if it doesn't exist. Arguments: *<category> <command>*"),
                (Command.RemoveFromCategory.rawValue, "Remove a command from a category. Arguments: *<category> <command>*"),
                (Command.DeleteCategory.rawValue, "Delete an existing category. Commands in the category will not be removed. Arguments: *<category>*"),
                (Command.ListCommands.rawValue, "List existing custom commands and categories."),
        ];
    }

    override func handleCommand(command: String, args: [String], message: Message) -> Bool {
        guard let cmd = Command(rawValue: command) else {
            LOG_ERROR("Got sent invalid command: \(command) - odd")
            return false
        }
        switch (cmd) {
        case .AddCommand:
            addCommand(args, message: message)
        case .RemoveCommand:
            removeCommand(args, message: message)
        case .EditCommand:
            editCommand(args, message: message)
        case .SetHelpText:
            addHelp(args, message: message)
        case .AddToCategory:
            addToCategory(args, message: message)
        case .RemoveFromCategory:
            removeFromCategory(args, message: message)
        case .DeleteCategory:
            break;
        case .ListCommands:
            listCommands(args, message: message)
        }
        return true
    }

    override func handleAnything(command: String, args: [String], message: Message) -> Bool {
        let cdm = CoreDataManager.instance
        if let commandObject = cdm.loadCommandAlias(command) {
            if message.flags.contains(.Help) {
                if let help = commandObject.help {
                    var helpMessage = "**\(Config.commandPrefix)\(commandObject.command)**: \(help)";
                    if let longHelp = commandObject.longHelp {
                        let longHelpMessage = "\(helpMessage)\n\n\(longHelp)"
                        if commandObject.pmEnabled {
                            message.replyToSender(longHelpMessage)
                            helpMessage = "\(helpMessage) (see pm for details)"
                        } else {
                            helpMessage = longHelpMessage
                        }
                    }
                    message.replyToChannel(helpMessage)
                } else {
                    message.replyToChannel("**\(Config.commandPrefix)\(commandObject.command)**: No help available.")
                }
            } else {
                message.replyToChannel(commandObject.value)
            }
            return true
        }
        if let group = cdm.loadCommandGroup(command) {
            var output = ["**Category \(group.command)**: "]
            if let help = group.help {
                output[0] += help
            }
            let sortedCommands = group.commands.sort {
                $0.command > $1.command
            }
            for command in sortedCommands {
                var cmdline = "\t**\(Config.commandPrefix)\(command.command)**"
                if let help = command.help {
                    cmdline += ": \(help)"
                }
                output.append(cmdline)
            }
            message.replyToChannel(output.joinWithSeparator("\n"))
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
        if let existingCommand = cdm.loadCommandAlias(args[0]) {
            message.replyToChannel("Command *\(existingCommand.command)* already exist. Use *\(Config.commandPrefix)\(Command.EditCommand.rawValue)* instead.")
            return
        }
        if let _ = cdm.loadCommandGroup(args[0]) {
            message.replyToChannel("Error: Cannot add command *\(args[0])* since there's already a category with that name.")
            return
        }

        guard let commandText = getCommandText(args[0], message: message), command = cdm.createCommandAlias(args[0], value: commandText) else {
            LOG_ERROR("Command was not created.")
            message.replyToChannel("Internal error. Unable to create command alias.")
            return
        }
        cdm.save()
        message.replyToChannel("Command alias for *\(command.command)* created successfully.")
    }

    func editCommand(args: [String], message: Message) {
        if args.count < 2 {
            message.replyToChannel("Invalid syntax. Expected: <command> <new text>")
            return
        }
        let cdm = CoreDataManager.instance
        guard let existingCommand = cdm.loadCommandAlias(args[0]) else {
            message.replyToChannel("Command *\(args[0])* doesn't exist. Use *\(Config.commandPrefix)\(Command.AddCommand.rawValue)* instead.")
            return
        }

        guard let commandText = getCommandText(args[0], message: message) else {
            message.replyToChannel("Missing command text, check your arguments.");
            return
        }

        existingCommand.value = commandText
        cdm.save()
        message.replyToChannel("Command *\(existingCommand.command)* updated with new text.")
    }

    func removeCommand(args: [String], message: Message) {
        if args.count < 1 {
            message.replyToChannel("Invalid syntax. Expected: <command>")
            return
        }
        let cdm = CoreDataManager.instance
        guard let existingCommand = cdm.loadCommandAlias(args[0]) else {
            message.replyToChannel("Command *\(args[0])* doesn't exist.")
            return
        }
        if cdm.deleteObject(existingCommand) {
            message.replyToChannel("Command *\(args[0])* removed.")
            cdm.save()
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
        var entryToUpdate: Commandable? = cdm.loadCommandAlias(args[0])
        if entryToUpdate == nil {
            entryToUpdate = cdm.loadCommandGroup(args[0])
        }

        if let entryToUpdate = entryToUpdate {
            entryToUpdate.help = getCommandText(args[0], message: message)
            message.replyToChannel("Command or category *\(entryToUpdate.command)* updated with help text.")
            cdm.save()
            return
        }

        message.replyToChannel("Command or category *\(args[0])* doesn't exist.")
    }

    func listCommands(args: [String], message: Message) {
        let cdm = CoreDataManager.instance
        let sortOrder = [NSSortDescriptor(key: "command", ascending: true)]
        var output = [""]
        if let groups = cdm.fetchObjectsOfType(.CommandGroup, withPredicate: nil, sortedBy: sortOrder) {
            output.append("**Categories**:\n\t\(groups.map {" **\($0.command)**:\($0.commands.map { $0.command }.joinWithSeparator(", "))"}.joinWithSeparator("\n\t"))")
            } else {
            output.append("**Categories**:\n\tNone found")
        }
        if let commands = cdm.fetchObjectsOfType(.CommandAlias, withPredicate: nil, sortedBy: sortOrder) as? [CommandAlias] {
            output.append("\n**Commands**:\n\t\(commands.filter { $0.group == nil }.map { $0.command }.joinWithSeparator(", "))")
        } else {
            output.append("\n**Commands**: None found")
        }

        let outputString = output.joinWithSeparator("\n")
        if args.count > 0 && args[0] == "here" {
            message.replyToChannel(outputString)
        } else {
            message.replyToSender(outputString)
        }

    }
}

// MARK: Command grouping for fun and profit

extension CustomCommandMessageHandler {
    func loadOrCreateCommandGroup(group: String, shouldCreate: Bool = true) -> CommandGroup? {
        let cdm = CoreDataManager.instance
        if let group = cdm.loadCommandGroup(group) {
            return group
        }
        if !shouldCreate {
            return nil
        }
        return cdm.createCommandGroup(group)
    }

    func addToCategory(args: [String], message: Message) {
        if args.count < 2 {
            message.replyToChannel("Invalid syntax. Expected: <category> <command>")
            return
        }
        let cdm = CoreDataManager.instance
        guard let command = cdm.loadCommandAlias(args[1]) else {
            message.replyToChannel("Command *\(args[1])* doesn't exist.")
            return
        }
        if let _ = cdm.loadCommandAlias(args[0]) {
            message.replyToChannel("Error: Cannot add category *\(args[0])* since there's already a command with that name.")
            return
        }

        guard let group = loadOrCreateCommandGroup(args[0]) else {
            message.replyToChannel("Internal Error: Unable to load or create category *\(args[0])*.")
            return
        }
        if group.commands.contains(command) {
            message.replyToChannel("Command *\(command.command)* already in category *\(group.command)*.")
            return
        }
        group.commands.insert(command)
        cdm.save()
        message.replyToChannel("Command *\(command.command)* added to category *\(group.command)*.")
    }

    func removeFromCategory(args: [String], message: Message) {
        if args.count < 2 {
            message.replyToChannel("Invalid syntax. Expected: <category> <command>")
            return
        }
        let cdm = CoreDataManager.instance
        guard let command = cdm.loadCommandAlias(args[1]) else {
            message.replyToChannel("Command *\(args[1])* doesn't exist.")
            return
        }
        guard let group = loadOrCreateCommandGroup(args[0], shouldCreate: false) else {
            message.replyToChannel("Category *\(args[0])* doesn't exist.")
            return
        }
        if group.commands.contains(command) {
            message.replyToChannel("Command *\(command.command)* removed from category *\(group.command)*.")
            group.commands.remove(command)
            cdm.save()
            return
        }

        message.replyToChannel("Command *\(command.command)* is not part of category *\(group.command)*.")
    }
}


class CustomCommandImportMessageHandler: AuthenticatedMessageHandler {
    override var commands: [MessageCommand]? {
        return [
                ("importcmds", "Import commands from a specified URL. Requires administrator role.")
        ]
    }
    override var commandGroup: String? {
        return CustomCommandMessageHandler.CustomCommandGroup
    }
    override func handleAuthenticatedCommand(command: String, args: [String], message: Message) -> Bool {
        importCommands(args, message: message)
        return true
    }

    private func importCommands(args: [String], message: Message) {
        if args.count < 1 {
            message.replyToChannel("Import URL is missing.")
            return
        }
        guard let url = NSURL(string: args[0]) else {
            message.replyToChannel("Invalid URL provided.")
            return
        }

        if url.fileURL {
            // File URL requires owners permissions
            if let senderId = message.author?.id {
                if !Config.ownerIds.contains(senderId) {
                    message.replyToChannel("File URL access is restricted to bot owners.")
                    return
                }
            }
        }

        let task = NSURLSession.sharedSession().downloadTaskWithURL(url, completionHandler: {
            (location: NSURL?, response: NSURLResponse?, error: NSError?) in
            if let error = error {
                message.replyToSender("Failed to import due to error: \(error).")
                return
            }
            if let location = location {
                do {
                    let importer = CustomCommandImporter()
                    let data = try NSData(contentsOfURL: location, options: NSDataReadingOptions.DataReadingMappedAlways)
                    let result = try importer.importFromData(data)
                    message.replyToChannel("Imported \(result.cmdImported) commands, updated \(result.cmdUpdated) commands and added \(result.catImported) categories")
                } catch CustomComandImportError.UTF8DecodingFailure {
                    message.replyToSender("Failed to import due failure to decode data as UTF-8.")
                } catch CustomComandImportError.YamlError(let errorMsg) {
                    if let msg = errorMsg {
                        message.replyToSender("Failed to import due failure to Yaml error: \(msg)")
                    } else {
                        message.replyToSender("Failed to import due failure to unknown Yaml error.")
                    }
                } catch {
                    message.replyToSender("Failed to open download data for reading: \(error)")
                }
            } else {
                message.replyToSender("No data returned from network call.")
            }
        })
        task.resume()
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
             DeleteCategory = "delcat",
             ListCommands = "listcmds"
    }

}
