//
// Created by David Hedbor on 2/15/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI
import Yaml

enum CustomComandImportError: ErrorType {
    case UTF8DecodingFailure,
         YamlError(error:String?)


}

@objc public class CustomCommandImporter: NSObject {
    override public init() {
        // Init without doing anything, used when executed from message handler.
        super.init()
    }

    public func importFromData(data: NSData, synchronous: Bool = false) throws -> (cmdImported:Int, catImported:Int, cmdUpdated:Int) {
        guard let filestring = String(data: data, encoding: NSUTF8StringEncoding) else {
            throw CustomComandImportError.UTF8DecodingFailure
        }
        var cmdImported = 0
        var catImported = 0
        var cmdUpdated = 0
        let importCmd = Yaml.load(filestring)
        if let topLevel = importCmd.value?.dictionary {
            var categoryHelp = [String: String]()
            if let categories = topLevel["categories"]?.dictionary {
                for (cat, catHelp) in categories {
                    if let catTxt = cat.string, catHelpTxt = catHelp.string {
                        categoryHelp[catTxt] = catHelpTxt
                    }
                }
            }
            LOG_DEBUG("Category help: \(categoryHelp)");
            if let commands = topLevel["commands"]?.dictionary {
                let cdm = CoreDataManager.instance
                for (command, dict) in commands {
                    guard let commandStr = command.string, commandDict = dict.dictionary, content = commandDict["content"]?.dictionary, commandText = content["text"]?.string else {
                        throw CustomComandImportError.YamlError(error: "Command \(command) missing a name or required content.")
                    }
                    var cmdObject = cdm.loadCommandAlias(commandStr)
                    if cmdObject == nil {
                        cmdObject = cdm.createCommandAlias(commandStr, value: commandText)
                        cmdImported += 1
                    } else {
                        cmdObject?.value = commandText
                        cmdUpdated += 1
                    }

                    LOG_DEBUG("Importing \(commandStr): \(commandText)")

                    cmdObject?.help = content["short_help"]?.string
                    cmdObject?.longHelp = content["extended_help"]?.string

                    if let optionsDict = commandDict["options"]?.dictionary {
                        if let category = optionsDict["category"]?.string {
                            var catObj = cdm.loadCommandGroup(category)
                            if catObj == nil {
                                catObj = cdm.createCommandGroup(category)
                                catImported += 1
                            }
                            catObj?.commands.insert(cmdObject!)
                            if let catHelp = categoryHelp[category] {
                                catObj?.help = catHelp
                            }
                        }
                        if let pm = optionsDict["detailed_pm"]?.bool {
                            cmdObject?.pmEnabled = pm
                        }
                    }
                }
                cdm.save(synchronous)
            }
        } else {
            throw CustomComandImportError.YamlError(error: importCmd.error)
        }
        return (cmdImported, catImported, cmdUpdated)
    }
}
