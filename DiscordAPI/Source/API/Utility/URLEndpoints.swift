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
         Channel = "channels",
         User = "users"
}

class Endpoints {
    class func Simple(endpoint: URLEndpoint) -> String {
        return "https://discordapp.com/api/\(endpoint.rawValue)"
    }

    class func Channel(channel: String) -> String {
        return "\(Simple(.Channel))/\(channel)/messages"
    }

    class func User(userId: String, endpoint: URLEndpoint) -> String {
        return "\(Simple(.User))/\(userId)/\(endpoint.rawValue)"
    }
}
