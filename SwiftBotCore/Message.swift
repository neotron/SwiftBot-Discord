//
// Created by David Hedbor on 2/14/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI

class Message {
    let message: MessageModel
    let event: MessageEventType
    weak var discord: Discord?

    // Convenience wrappers
    var author   : UserModel? { return message.author }
    var mentions : [UserModel]? { return message.mentions }
    var content  : String       { return message.content! } // Content here is verified

    init(message: MessageModel, event: MessageEventType, discord: Discord?) {
        self.discord = discord
        self.message = message
        self.event = event
    }


    func replyToChannel(reply: String, tts: Bool = false, mentions: [String]? = nil)
    {
        guard let channel = message.channelId else {
            LOG_ERROR("Couldn't send reply message - missing channel id in message.");
            return
        }
        sendReplyMessage(reply, toChannel: channel, tts: tts, mentions: mentions)
    }

    func replyToSender(reply: String, tts: Bool = false, mentions: [String]? = nil)
    {
        guard let channel = message.author?.id else {
            LOG_ERROR("Couldn't send reply message - missing author id in message.");
            return
        }
        sendReplyMessage(reply, toChannel: channel, tts: tts, mentions: mentions)
    }

    private func sendReplyMessage(reply: String, toChannel channel: String, tts: Bool, mentions: [String]?) {
        self.discord?.sendMessage(reply, channel: channel, tts: tts, mentions: mentions)
    }
}
