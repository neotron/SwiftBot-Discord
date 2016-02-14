//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper

class SendMessageRequest {
    var content: String = ""
    var mentions: [String] = []
    var nonce: String
    var tts = false

    init(content: String, mentions: [String]? = nil) {
        self.content = content
        if let mentions = mentions {
            self.mentions = mentions
        }
        self.nonce = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "", options: [])
    }

    private func createMessage() -> [String:AnyObject] {
        return [
                "content": self.content,
                "mentions": self.mentions,
                "nonce": self.nonce,
                "tts" : self.tts
        ]
    }

    func sendOnChannel(channelId: String) {
        guard let token = Registry.instance.token else {
            LOG_ERROR("No authorization token found.")
            return
        }
        Alamofire.request(.POST, ChannelURL(channelId), headers: ["Authorization": token], parameters:createMessage(), encoding: .JSON).responseObject {
            (response: Response<MessageModel, NSError>) in
            print("message is \(response.result.value)")
        }
    }
}

