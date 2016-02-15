//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI

class PingMessageHandler : MessageHandler {
    private let PING = "ping"
    private let PONG = "pong"
    private let PINGME = "pingme"

    override var commands: [MessageCommand]? {
        return [(PING, "Sends a pong message back to you."),
                (PONG, "Pings you back delightfully."),
                (PINGME, "Pongs you in a personal message.")]
    }

    override func handleCommand(command: String, args: [String], message: Message) -> Bool {
        switch(command) {
        case PONG:
            message.replyToChannel("Ping!")
        case PING:
            message.replyToChannel("Pong!")
        case PINGME:
            message.replyToSender("Pong!")
        default:
            return false
        }
        return true
    }

}
