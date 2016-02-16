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
        registerMessageHandlers()
        print("Database coordinator = \(CoreDataManager.instance.persistentStoreCoordinator)")
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

    private func registerMessageHandlers() {
        self.messageDispatcher.registerMessageHandler(PingMessageHandler())
        self.messageDispatcher.registerMessageHandler(RandomAnimalsMessageHandler())
        self.messageDispatcher.registerMessageHandler(ScienceMessageHandler())
        self.messageDispatcher.registerMessageHandler(IdentifierMessageHandler())
        self.messageDispatcher.registerMessageHandler(CustomCommandMessageHandler())
    }


}
