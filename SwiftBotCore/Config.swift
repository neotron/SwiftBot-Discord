//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import ObjectMapper
import DiscordAPI

class Config : MappableBase {
    var email = "NOT CONFIGURED"
    var password = "NOT CONFIGUREd"
    var commandPrefix = "~"

    init(withFile configFile: String) {
        super.init()
        if let configData = NSData(contentsOfFile: configFile), configString = String(data: configData, encoding: NSUTF8StringEncoding) {
            Mapper().map(configString, toObject: self)
        } else {
            LOG_ERROR("Failed to open config file \(configFile)")
        }
    }

    required init?(_ map: Map) {
        super.init(map)
    }

    override func mapping(map: Map) {
        email    <- map["auth.email"]
        password <- map["auth.password"]
    }

}
