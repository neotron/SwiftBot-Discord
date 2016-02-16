//
// Created by David Hedbor on 2/15/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI
import Yaml

@objc public class CustomCommandImporter: NSObject {
    public init(configFile: String) {
        Config.instance.loadConfig(fromFile: configFile)
        super.init()
        if !CoreDataManager.instance.isSetupAndWorking() {
            LOG_ERROR("Unable to open database. Check your configuration!")
            exit(1)
        }
    }

    public func importFromFile(file: String) {
        guard let filedata = NSData(contentsOfMappedFile: file) else {
            LOG_ERROR("Failed to load import file \(file).")
            exit(1)
        }
        guard let filestring = String(data: filedata, encoding: NSUTF8StringEncoding) else {
            LOG_ERROR("Failed to decode import file \(file) as utf-8.")
            exit(1)
        }
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
                } else {
                    cmdObject?.value = commandText
                }
                cmdObject?.help = commandHelp
                if let category = category {
                    var catObj = cdm.loadCommandGroup(category)
                    if catObj == nil {
                        catObj = cdm.createCommandGroup(category)
                    }
                    catObj?.commands.insert(cmdObject!)
                }
            }
            cdm.save()
        }
    }
}
