//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Main interface point with the Discord API

import Foundation

public protocol DiscordDelegate : class {
    func discordLoginDidComplete(error: NSError?)
    func discordWebsocketEndpointError(error: NSError?)
    func discordMessageReceived(message: MessageModel, event: MessageEventType)
}

public class Discord: WebsocketAPIManagerDelegate {
    private var websocketManager: WebsocketAPIManager

    public weak var delegate: DiscordDelegate?

    public init() {
        self.websocketManager = WebsocketAPIManager()
        self.websocketManager.delegate = self
    }

    public func login(user: String, password: String) {
        let login = LoginRequest(user, password: password)
        login.execute({ (login: LoginResponseModel?, error: NSError?) in
            self.delegate?.discordLoginDidComplete(error)
            if error == nil {
                self.websocketManager.fetchEndpointAndConnect()
            }
        });
    }

    public func sendMessage(message: String, channel: String, tts: Bool = false, mentions: [String]? = nil) {
        let messageSender = SendMessageRequest(content: message, mentions: mentions)
        messageSender.tts = tts
        messageSender.sendOnChannel(channel)
    }

    public func sendPrivateMessage(message: String, recipientId: String) {
        let privateChannelRequest = PrivateChannelRequest(recipientId: recipientId)
        privateChannelRequest.execute({ (channelId: String?) in
            guard let channelId = channelId else {
                LOG_ERROR("Cannot send private message - failed to get channel")
                return
            }
            self.sendMessage(message, channel: channelId)
        })
    }

    public func websocketEndpointError() {
        delegate?.discordWebsocketEndpointError(NSError(domain: "Discord", code: -1, userInfo: nil))
    }

    public func websocketMessageReceived(message: MessageModel, event: MessageEventType) {
        delegate?.discordMessageReceived(message, event: event)
    }


}
