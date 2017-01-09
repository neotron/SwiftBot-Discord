//
// Created by David Hedbor on 2/15/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import SwiftDiscord
import Yaml

enum CustomComandImportError: Error {
    case utf8DecodingFailure,
         yamlError(error:String?)


}

@objc open class CustomCommandImporter: NSObject {
    override public init() {
        // Init without doing anything, used when executed from message handler.
        super.init()
    }

    open func importFromData(_ data: Data, synchronous: Bool = false) throws -> (cmdImported:Int, catImported:Int, cmdUpdated:Int) {
        guard let filestring = String(data: data, encoding: String.Encoding.utf8) else {
            throw CustomComandImportError.utf8DecodingFailure
        }
        var cmdImported = 0
        var catImported = 0
        var cmdUpdated = 0
        let topLevel = try Yaml.load(filestring)
        var categoryHelp = [String: String]()
        if let categories = topLevel["categories"].dictionary {
            for (cat, catHelp) in categories {
                if let catTxt = cat.string, let catHelpTxt = catHelp.string {
                    categoryHelp[catTxt] = catHelpTxt
                }
            }
        }
        LOG_DEBUG("Category help: \(categoryHelp)");
        if let commands = topLevel["commands"].dictionary {
            let cdm = CoreDataManager.instance
            for (command, dict) in commands {
                guard let commandStr = command.string, let commandDict = dict.dictionary, let content = commandDict["content"]?.dictionary, let commandText = content["text"]?.string else {
                    throw CustomComandImportError.yamlError(error: "Command \(command) missing a name or required content.")
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
        return (cmdImported, catImported, cmdUpdated)
    }
}
