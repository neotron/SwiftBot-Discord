//
// Created by David Hedbor on 2/12/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper

class GatewayUrlRequest {
    public func execute(callback: ((Bool)->Void)?) {
        guard let token = Registry.instance.token else {
            LOG_ERROR("Cannot retrieve endpoint, login first.")
            callback?(false)
            return
        }
        Alamofire.request(.GET, EndpointURL(.Gateway), headers: [
                "Content-Type": "application/json",
                "User-Agent": Registry.userAgent,
                "Authorization": token
        ]).responseObject {
            (response: Response<GatewayUrlResponseModel, NSError>) in
            var success = false
            if let url = response.result.value?.url {
                Registry.instance.websocketEndpoint = url
                LOG_INFO("Retrieved websocket endpoint: \(url)")
                success = true
            } else {
                LOG_ERROR("Failed to retrieve websocket endpoint: \(response.result.error)");
            }
            callback?(success)
        }
    }
}
