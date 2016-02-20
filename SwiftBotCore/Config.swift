//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI
import EVReflection

class ConfigAuth : EVObject {
    var email = "NOT CONFIGURED"
    var password = "NOT CONFIGURED"
}

class Config: EVObject {
    // Instance accessible read-only settings.
    static var email: String {
        return instance.auth.email
    }
    static var password: String {
        return instance.auth.password
    }
    static var commandPrefix: String {
        return instance.commandPrefix
    }
    static var databaseDirectory: String? {
        return instance.databaseDirectory
    }
    static var ownerIds: Set<String> {
        return Set(instance.ownerIds)
    }

    // Internal private storage
    var auth = ConfigAuth()
    var commandPrefix = "~"
    var databaseDirectory: String?
    var ownerIds = [String]()

    class func loadConfig(fromFile configFile: String) {
        if let configData = NSData(contentsOfFile: configFile), configString = String(data: configData, encoding: NSUTF8StringEncoding) {
            EVReflection.setBundleIdentifier(SwiftBotMain)
            _instance = Config(json: configString)
        } else {
            LOG_ERROR("Failed to open config file \(configFile)")
        }
    }

    private static var instance: Config {
        guard let ins = _instance else { return Config() }
        return ins
    }
    private static var _instance: Config?
}
