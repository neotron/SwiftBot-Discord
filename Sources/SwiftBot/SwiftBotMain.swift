//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import AppKit
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
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "DiscordAuthenticationChanged"), object: nil,
                queue: OperationQueue.current, using: {
            (notification: Notification) in
            if let token = notification.userInfo?["token"] as? String {
                self.discord.updateLoginWithToken(token)
            }
        });
    }

    open func runWithDoneCallback(_ callback: ((Void) -> Void)?) {
        self.doneCallback = callback
        let account = DiscordAccount()
        self.discord.login(account.token)
    }

    open func discordLoginDidComplete(_ error: NSError?) {
        if let _ = error {
            let alert = NSAlert();
            alert.addButton(withTitle: "OK")
            alert.messageText = "Failed to login to Discord."
            alert.informativeText = "An error occurred while attempting to connect to Discord. Please check your credentials in the preferences."
            alert.alertStyle = .critical
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    open func discordWebsocketEndpointError(_ error: NSError?) {
        LOG_ERROR("Exiting due to websocket endpoint error: \(error)")
        self.doneCallback?()
    }

    open func discordMessageReceived(_ message: MessageModel, event: MessageEventType) {
        self.messageDispatcher.processMessage(message, event: event)
    }

}
