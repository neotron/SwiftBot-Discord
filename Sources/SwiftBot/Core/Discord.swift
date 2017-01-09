//
// Created by David Hedbor on 2017-01-08.
//

import Foundation
import SwiftDiscord

public protocol DiscordDelegate : class {
    func discordLoginDidComplete(_ error: NSError?)
    func discordWebsocketEndpointError(_ error: NSError?)
    func discordMessageReceived(_ message: DiscordMessage, event: MessageEventType)
}

class Discord {
    fileprivate let client: DiscordClient
    var delegate: DiscordDelegate?

    init() {
        client = DiscordClient(token: Config.authToken, configuration: [])
        attachHandlers()
        client.connect()
    }


    func connect() {
        client.connect()
    }

    fileprivate func attachHandlers() {
        client.on("messageCreate") { [weak self] data in
            guard let this = self, let message = data[0] as? DiscordMessage else { return }
            this.delegate?.discordMessageReceived(message, event: .Create)
        }
        client.on("messageUpdate") { [weak self] data in
            guard let this = self, let message = data[0] as? DiscordMessage else { return }
            this.delegate?.discordMessageReceived(message, event: .Update)
        }
        client.on("connect") { [weak self] data in
            guard let this = self else { return }
            LOG_DEBUG("Bot connected: \(data)")
            LOG_DEBUG("\(this.client.getBotURL(with: [.sendMessages, .readMessages])!)")
            this.delegate?.discordLoginDidComplete(nil)
         }

         client.on("disconnect") {data in
             print("bot disconnected")
         }
    }


}
