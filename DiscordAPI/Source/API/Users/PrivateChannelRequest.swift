//
// Created by David Hedbor on 2/14/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import ObjectMapper

// Not exposed
private class PrivateChannelResponseModel : MappableBase {
    var channelId: String?

    override func mapping(map: Map) {
        channelId   <- map["id"]
    }
}

public class PrivateChannelRequest {
    private var recipientId: String

    public init(recipientId: String) {
        self.recipientId = recipientId
    }

    public func execute(callback: (String?)->Void) {
        guard let token = Registry.instance.token else {
            LOG_ERROR("No authorization token found.")
            return
        }
        guard let userId = Registry.instance.user?.id else {
            LOG_ERROR("No authorization token found.")
            return
        }
        Alamofire.request(.POST, Endpoints.User(userId, endpoint: .Channel), headers: ["Authorization": token], parameters:["recipient_id": recipientId], encoding: .JSON).responseObject {
            (response: Response<PrivateChannelResponseModel, NSError>) in
            print("Private channel is \(response.result.value)")
            if let channelId = response.result.value?.channelId {
                callback(channelId)
            } else {
                if let error = response.result.error {
                    LOG_ERROR("Failed to create private channel: \(error)")
                }
                callback(nil)
            }
        }
    }
}
