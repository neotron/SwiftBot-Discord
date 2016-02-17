//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI

public class SwiftBotMain : NSObject, DiscordDelegate {
    private let discord = Discord()
    private var doneCallback: ((Void)->Void)?
    private let messageDispatcher: MessageDispatchManager


    public init(withConfigFile configFile: String) {
        Config.instance.loadConfig(fromFile: configFile);
        self.messageDispatcher = MessageDispatchManager()
        super.init()

        self.discord.delegate = self
        self.messageDispatcher.discord = discord
        let cdm = CoreDataManager.instance

        if !cdm.isSetupAndWorking() {
            LOG_ERROR("NOTE: The database couldn't be initialized (check configuration). Custom commands will not work.")
        } else {
            cdm.updateOwnerRolesFromConfig()
        }
    }

    public func runWithDoneCallback(callback: ((Void)->Void)?) {
        self.doneCallback = callback
        self.discord.login(Config.email, password: Config.password)
    }

    public func discordLoginDidComplete(error: NSError?) {
        if(error != nil) {
            LOG_ERROR("Exiting due to login failure")
            self.doneCallback?()
        }
    }

    public func discordWebsocketEndpointError(error: NSError?) {
        LOG_ERROR("Exiting due to websocket endpoint error: \(error)")
        self.doneCallback?()
    }

    public func discordMessageReceived(message: MessageModel, event: MessageEventType) {
        self.messageDispatcher.processMessage(message, event: event)
    }

}
