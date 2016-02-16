//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import ObjectMapper
import DiscordAPI

class Config : MappableBase {
    static let instance = Config()

    // Instance accessible read-only settings.
    static var email: String             { return instance._email }
    static var password: String          { return instance._password }
    static var commandPrefix: String     { return instance._commandPrefix }
    static var databaseDirectory: String? { return instance._databaseDirectory }

    // Internal private storage
    private var _email = "NOT CONFIGURED"
    private var _password = "NOT CONFIGUREd"
    private var _commandPrefix = "~"
    private var _databaseDirectory: String?

    override init() {
        super.init()
    }

    func loadConfig(fromFile configFile: String) {
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
        _email    <- map["auth.email"]
        _password <- map["auth.password"]
        _commandPrefix <- map["command_prefix"]
        _databaseDirectory <- map["database_directory"]
    }

}
