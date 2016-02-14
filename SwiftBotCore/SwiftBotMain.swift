//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI

public class SwiftBotMain : NSObject, DiscordDelegate {
    private let config : Config
    private let discord = Discord()
    private var doneCallback: ((Void)->Void)?
    private let messageDispatcher: MessageDispatchManager


    public init(withConfigFile configFile: String) {
        self.config = Config(withFile: configFile);
        self.messageDispatcher = MessageDispatchManager(withConfig: self.config)
        super.init()

        self.discord.delegate = self
        self.messageDispatcher.discord = discord
        registerMessageHandlers()
    }

    public func runWithDoneCallback(callback: ((Void)->Void)?) {
        self.doneCallback = callback
        self.discord.login(config.email, password: config.password)
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

    private func registerMessageHandlers() {
        self.messageDispatcher.registerMessageHandler(PingMessageHandler())
        self.messageDispatcher.registerMessageHandler(RandomAnimalsMessageHandler())
        self.messageDispatcher.registerMessageHandler(ScienceMessageHandler())
    }


}
