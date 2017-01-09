//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import SwiftDiscord

open class SwiftBotMain: NSObject, DiscordDelegate {
    fileprivate let discord = Discord()
    fileprivate var doneCallback: ((Void) -> Void)?
    fileprivate let messageDispatcher: MessageDispatchManager

    override public init() {
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

    open func runWithDoneCallback(_ callback: ((Void) -> Void)?) {
        self.doneCallback = callback
        self.discord.connect()
    }

    open func discordLoginDidComplete(_ error: NSError?) {
        if let error = error {
            LOG_ERROR("Failed to login: \(error.localizedDescription)")
            self.doneCallback?()
        }
    }

    open func discordWebsocketEndpointError(_ error: NSError?) {
        LOG_ERROR("Exiting due to websocket endpoint error: \(error)")
        self.doneCallback?()
    }

    open func discordMessageReceived(_ message: DiscordMessage, event: MessageEventType) {
        self.messageDispatcher.processMessage(message, event: event)
    }

}
