//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import SwiftDiscord
import Mapper

fileprivate struct ConfigData: Mappable {
    // Internal private storage
    let commandPrefix: String
    let databaseDirectory: String
    let ownerIds: [String]
    let authToken: String
    var development = false {
        didSet {
            let center = NotificationCenter.default
            center.post(Notification(name: Notification.Name(rawValue: Config.CONFIG_CHANGE_KEY), object: nil))
        }
    }

    init(map: Mapper) throws {
        commandPrefix = map.optionalFrom("command_prefix") ?? "~"
        try databaseDirectory = map.from("database_directory")
        try authToken = map.from("auth")
        ownerIds = map.optionalFrom("owner_ids") ?? []
        development = map.optionalFrom("development") ?? false
    }

}

class Config {
    static let CONFIG_CHANGE_KEY = "ApplicationModeChange"

    // Instance accessible read-only settings.
    static var commandPrefix: String {
        return instance.config!.commandPrefix
    }
    static var databaseDirectory: String? {
        return instance.config!.databaseDirectory
    }
    static var ownerIds: Set<String> {
        return Set(instance.config!.ownerIds)
    }
    static var development: Bool {
        return instance.config?.development ?? true
    }
    static var authToken: DiscordToken {
        return DiscordToken(stringLiteral: "Bot \(instance.config!.authToken)")
    }

    // Internal stuff
    private var config: ConfigData?
    fileprivate static let instance = Config()

    static func loadConfigFrom(file: String) {
        if let json = JSON.from(file: file) {
            instance.config = ConfigData.from(json)
        }
        guard let _ = instance.config else {
            LOG_ERROR("Failed to load configuration: \(file)")
            exit(1)
        }
    }
}
