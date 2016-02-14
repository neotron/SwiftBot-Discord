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
        url <- map["figitle"]
    }

}

class RandomAnimalsMessageHandler: MessageHandler {

    var prefixes: [String]? {
        return ["random"]
    }
    var commands: [String]? {
        return ["random"]
    }
    func handlePrefix(prefix: String, command: String, args: [String], message: MessageModel, event: MessageEventType, completeCallback: (responseMessage:String?, privateMessage:Bool?) -> (Void)) -> Bool {
        switch(command) {
        case "randomcat":
            handleRandomCat(completeCallback)
        case "randomdog":
            completeCallback(responseMessage: "http://www.randomdoggiegenerator.com/randomdoggie.php/\(NSDate().timeIntervalSince1970).jpg", privateMessage: false)
        case "randomkitten":
            completeCallback(responseMessage: "http://www.randomkittengenerator.com/cats/rotator.php/\(NSDate().timeIntervalSince1970).jpg", privateMessage: false)
        default:
            return false
        }
        return true
    }

    func handleCommand(command: String, args: [String], message: MessageModel, event: MessageEventType, completeCallback: (responseMessage:String?, privateMessage:Bool?) -> (Void)) -> Bool {
        if args.count > 0 {
            return false // Only handle empty random
        }
        completeCallback(responseMessage: "I know of the following random images: cat, dog and kitten.", privateMessage: false)
        return true
    }


    private func handleRandomCat(completeCallback: (responseMessage:String?, privateMessage:Bool?) -> (Void)) {

        Alamofire.request(.GET, "http://random.cat/meow").responseObject {
            (response: Response<MeowModel, NSError>) in

            if let meow = response.result.value, url = meow.url {
                completeCallback(responseMessage: url, privateMessage: false)
            } else {
                completeCallback(responseMessage: "Unfortunately, I failed to find any random cats for you today. :-(", privateMessage: false)
                LOG_ERROR("Failed to get meow: \(response.result.error)")
            }
        }
    }

}
