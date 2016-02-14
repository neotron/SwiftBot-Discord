//
// Created by David Hedbor on 2/12/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import Alamofire

enum URLEndpoint: String {
    case Login  = "auth/login",
         Logout = "auth/logout",
         Gateway = "gateway",
         Channel = "channels"
}

func EndpointURL(endpoint: URLEndpoint) -> String {
    return "https://discordapp.com/api/\(endpoint.rawValue)"
}

func ChannelURL(channel: String) -> String {
    return "\(EndpointURL(.Channel))/\(channel)/messages"
}
