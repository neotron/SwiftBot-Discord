//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI

class PingMessageHandler : MessageHandler {
    private let PING = "ping"
    private let PONG = "pong"

    override var commands: [String]? {
        return [PING, PONG]
    }

    override func handleCommand(command: String, args: [String], message: Message) -> Bool {
        switch(command) {
        case PONG:
            message.replyToChannel("Ping!")
        case PING:
            message.replyToChannel("Pong!")
        default:
            return false
        }
        return true
    }

}
