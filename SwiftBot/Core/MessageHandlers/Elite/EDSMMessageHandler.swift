//
// Created by David Hedbor on 2/25/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import EVReflection
import Alamofire
import AlamofireJsonToObjects
import DiscordAPI

// {"msgnum":100,"msg":"OK","system":"Phipoea DD-F c26-1311","firstDiscover":false,"date":"2016-02-25 06:44:54"}

class CommanderPositionModel : EVObject {
    var msg: String = ""
    var msgnum: Int = 0
    var system: String?
    var firstDiscover: Bool = false
    var date: String?
}

class EDSMMessageHandler : MessageHandler {
    override var commands: [MessageCommand]? {
        return [("loc", "Try to get a commanders location from EDSM. Syntax: loc <commander name>")]
    }
    override var commandGroup: String? {
        return "EDSM Api Queries"
    }
    override func handleCommand(command: String, args: [String], message: Message) -> Bool {
        switch(command) {
        case "loc":
            handleLocationLookup(args.joinWithSeparator(" "), message: message)
        default:
            return false
        }
        return true
    }

    private func handleLocationLookup(commander: String, message: Message) {

        Alamofire.request(.GET, "http://www.edsm.net/api-logs-v1/get-position/", parameters: ["commanderName": commander]).responseObject {
            (response: Result<CommanderPositionModel, NSError>) in
            guard let location = response.value else {
                message.replyToChannel("Failed to complete request.")
                LOG_ERROR("Get Position api failed with error \(response.error)")
                return
            }
            if let system = location.system {
                var output = "\(commander) was last seen in \(system)";
                if let date = location.date {
                    output += " at \(date)"
                }
                message.replyToChannel("\(output).")
            } else {
                switch location.msgnum {
                case 100:
                    message.replyToChannel("I have no idea where \(commander) is - perhaps they aren't sharing their position?")
                case 203:
                    message.replyToChannel("There's no known commander by the name \(commander).");
                default:
                    message.replyToChannel("Some error happened.");
                }
            }
        }
    }

}
