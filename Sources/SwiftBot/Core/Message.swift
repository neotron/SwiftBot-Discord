//
// Created by David Hedbor on 2/14/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import SwiftDiscord

public enum MessageEventType
{
    case Create, Update
}

class Message {
    let message: DiscordMessage
    let event: MessageEventType
    weak var discord: Discord?

    // Convenience wrappers
    var author: DiscordUser? {
        return message.author
    }
    var mentions: [DiscordUser]? {
        return message.mentions
    }
    var content: String {
        return message.content
    }
    var isPrivateMessage: Bool {
        return message.author.id == message.channelId
    }
    // Content here is verified
    var rawArgs: [String]?
    // Arguments, without space removal
    var flags: CommandFlags

    init(message: DiscordMessage, event: MessageEventType, discord: Discord?, flags: CommandFlags) {
        self.discord = discord
        self.message = message
        self.event = event
        self.flags = flags
    }

    func replyToChannel(_ reply: String, tts: Bool = false, mentions: [String]? = nil) {
        message.channel?.sendMessage(reply, tts: tts)
    }

    func replyToSender(_ reply: String) {
        // TODO: FIXME
        //message.author.
        //self.discord?.sendPrivateMessage(reply, recipientId: message.author.id)
    }
}
