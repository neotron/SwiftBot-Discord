//
// Created by David Hedbor on 2/15/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI
import Yaml
enum CustomComandImportError: ErrorType {
    case UTF8DecodingFailure,
         YamlError(error: String?)


}
@objc public class CustomCommandImporter: NSObject {
    public init(configFile: String) {
        Config.instance.loadConfig(fromFile: configFile)
        super.init()
        if !CoreDataManager.instance.isSetupAndWorking() {
            LOG_ERROR("Unable to open database. Check your configuration!")
            exit(1)
        }
    }

    override public init() {
        // Init without doing anything, used when executed from message handler.
        super.init()
    }

    public func importFromFile(file: String) {
        do {
            let filedata = try NSData(contentsOfFile: file, options: NSDataReadingOptions.DataReadingMappedAlways)
            try importFromData(filedata)
        } catch {
            LOG_ERROR("Failed to load import file \(file): \(error)")
            exit(1)
        }
    }

    public func importFromData(data: NSData) throws -> (cmdImported: Int, catImported: Int, cmdUpdated: Int){
        guard let filestring = String(data: data, encoding: NSUTF8StringEncoding) else {
            throw CustomComandImportError.UTF8DecodingFailure
        }
        var cmdImported = 0
        var catImported = 0
        var cmdUpdated = 0
        let importCmd = Yaml.load(filestring)
        if let commands = importCmd.value?.dictionary {
            let cdm = CoreDataManager.instance
            for (command, dict) in commands {
                guard let commandStr = command.string, commandText = dict["cmd"].string else {
                    continue
                }
                let commandHelp = dict["txt"].string
                let category = dict["cat"].string
                LOG_DEBUG("Importing \(commandStr): \(commandText), cat=\(category), help=\(commandHelp)")
                var cmdObject = cdm.loadCommandAlias(commandStr)
                if cmdObject == nil {
                    cmdObject = cdm.createCommandAlias(commandStr, value: commandText)
                    cmdImported++
                } else {
                    cmdObject?.value = commandText
                    cmdUpdated++
                }
                cmdObject?.help = commandHelp
                if let category = category {
                    var catObj = cdm.loadCommandGroup(category)
                    if catObj == nil {
                        catObj = cdm.createCommandGroup(category)
                        catImported++
                    }
                    catObj?.commands.insert(cmdObject!)
                }
            }
            cdm.save()
        } else {
            throw CustomComandImportError.YamlError(error: importCmd.error)
        }
        return (cmdImported, catImported, cmdUpdated)
    }
}
