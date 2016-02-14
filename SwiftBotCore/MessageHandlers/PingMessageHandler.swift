//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI

class PingMessageHandler : MessageHandler {
    private let PING = "ping"
    private let PONG = "pong"

    var prefixes: [String]? {
        return nil
    }
    var commands: [String]? {
        return [PING, PONG]
    }
    func handlePrefix(prefix: String, command: String, args: [String], message: MessageModel, event: MessageEventType, completeCallback: (responseMessage:String?, privateMessage:Bool?) -> (Void)) -> Bool {
        return false
    }

    func handleCommand(command: String, args: [String], message: MessageModel, event: MessageEventType, completeCallback: (responseMessage:String?, privateMessage:Bool?) -> (Void)) -> Bool {
        switch(command) {
        case PONG:
            completeCallback(responseMessage: "Ping!", privateMessage: false)
        case PING:
            completeCallback(responseMessage: "Pong!", privateMessage: false)
        default:
            return false
        }
        return true
    }

}
