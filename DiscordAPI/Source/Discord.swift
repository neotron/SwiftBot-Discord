//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Main interface point with the Discord API

import Foundation

public protocol DiscordDelegate : class {
    func discordLoginDidComplete(_ error: NSError?)
    func discordWebsocketEndpointError(_ error: NSError?)
    func discordMessageReceived(_ message: MessageModel, event: MessageEventType)
}

open class Discord: WebsocketAPIManagerDelegate {
    fileprivate var websocketManager: WebsocketAPIManager
    open weak var delegate: DiscordDelegate?

    public init() {
        self.websocketManager = WebsocketAPIManager()
        self.websocketManager.delegate = self
    }

    open func login(_ token: String? = nil) {
        if let token = token {
            Registry.instance.token = "Bot "+token
            self.websocketManager.fetchEndpointAndConnect()
        } else {
            LOG_ERROR("No bot token available, try again.")
            self.delegate?.discordLoginDidComplete(NSError(domain:"SwiftBotTokenMissing", code:-1, userInfo: nil))

        }
    }

    open func updateLoginWithToken(_ token: String) {
        Registry.instance.token = "Bot "+token
        self.websocketManager.fetchEndpointAndConnect()
    }

    open func sendMessage(_ message: String, channel: String, tts: Bool = false, mentions: [String]? = nil) {
        let messageSender = SendMessageRequest(content: message, mentions: mentions)
        messageSender.tts = tts
        messageSender.sendOnChannel(channelId: channel)
    }

    open func sendPrivateMessage(_ message: String, recipientId: String) {
        let privateChannelRequest = PrivateChannelRequest(recipientId: recipientId)
        privateChannelRequest.execute({ (channelId: String?) in
            guard let channelId = channelId else {
                LOG_ERROR("Cannot send private message - failed to get channel")
                return
            }
            self.sendMessage(message, channel: channelId)
        })
    }

    open func websocketEndpointError() {
        delegate?.discordWebsocketEndpointError(NSError(domain: "Discord", code: -1, userInfo: nil))
    }

    open func websocketMessageReceived(_ message: MessageModel, event: MessageEventType) {
        delegate?.discordMessageReceived(message, event: event)
    }

    // Typically means login is out-of-date, try to log in again
    open func websocketAuthenticationError() {
        self.delegate?.discordLoginDidComplete(NSError(domain:"SwiftBotTokenInvalid", code:-1, userInfo: nil))

    }

}
