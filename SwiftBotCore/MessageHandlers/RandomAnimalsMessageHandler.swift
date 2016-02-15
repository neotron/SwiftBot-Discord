//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI
import Alamofire
import AlamofireObjectMapper
import ObjectMapper

private class MeowModel: MappableBase {
    var url: String?
    override func mapping(map: Map) {
        url <- map["file"]
    }

}

class RandomAnimalsMessageHandler: MessageHandler {

    override var prefixes: [MessageCommand]? {
        return [("random", nil)]
    }
    override var commands: [MessageCommand]? {
        return [("random", "Show image of random animal. Supports cat, dog and kitten. Space between *random* and *animal* is optiona.")]
    }
    override func handlePrefix(prefix: String, command: String, args: [String], message: Message) -> Bool {
        switch(command) {
        case "randomcat":
            handleRandomCat(message)
        case "randomdog":
            message.replyToChannel("http://www.randomdoggiegenerator.com/randomdoggie.php/\(NSDate().timeIntervalSince1970).jpg")
        case "randomkitten":
            message.replyToChannel("http://www.randomkittengenerator.com/cats/rotator.php/\(NSDate().timeIntervalSince1970).jpg")
        default:
            return false
        }
        return true
    }

    override func handleCommand(command: String, args: [String], message: Message) -> Bool {
        switch(args.count) {
        case 0:
            message.replyToChannel("I know of the following random images: cat, dog and kitten.")
            return true
        case 1:
            return handlePrefix(command, command: "\(command)\(args[0].lowercaseString)", args: args, message: message)
        default:
            return false // Only handle empty random
        }
    }


    private func handleRandomCat(message: Message) {

        Alamofire.request(.GET, "http://random.cat/meow").responseObject {
            (response: Response<MeowModel, NSError>) in

            if let meow = response.result.value, url = meow.url {
                message.replyToChannel(url)
            } else {
                message.replyToChannel("Unfortunately, I failed to find any random cats for you today. :-(")
                LOG_ERROR("Failed to get meow: \(response.result.error)")
            }
        }
    }

}
