//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import AppKit
import DiscordAPI

public class SwiftBotMain: NSObject, DiscordDelegate {
    private let discord = Discord()
    private var doneCallback: ((Void) -> Void)?
    private let messageDispatcher: MessageDispatchManager

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
        NSNotificationCenter.defaultCenter().addObserverForName("DiscordAuthenticationChanged", object: nil,
                queue: NSOperationQueue.currentQueue(), usingBlock: {
            (notification: NSNotification) in
            if let token = notification.userInfo?["token"] as? String {
                self.discord.updateLoginWithToken(token)
            }
        });
    }

    public func runWithDoneCallback(callback: ((Void) -> Void)?) {
        self.doneCallback = callback
        let account = DiscordAccount()
        self.discord.login(account.email, password: account.password, token: account.token)
    }

    public func discordLoginDidComplete(error: NSError?) {
        if let _ = error {
            let alert = NSAlert();
            alert.addButtonWithTitle("OK")
            alert.messageText = "Failed to login to Discord."
            alert.informativeText = "An error occurred while attempting to connect to Discord. Please check your credentials in the preferences."
            alert.alertStyle = .CriticalAlertStyle
            NSApp.activateIgnoringOtherApps(true)
            alert.runModal()
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
