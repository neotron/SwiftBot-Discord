//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI
import EVReflection

@objc class Config: EVObject {
    // Instance accessible read-only settings.
    static var commandPrefix: String {
        get {
            return instance.commandPrefix
        }
        set {
            instance.commandPrefix = newValue
        }
    }
    static var databaseDirectory: String? {
        get {
            return instance.databaseDirectory
        } set {
            instance.databaseDirectory = newValue
            CoreDataManager.instance.reopenDatabase()
        }
    }
    static var ownerIds: Set<String> {
        get {
            return Set(instance.ownerIds)
        }
        set {
            instance.ownerIds = Array(newValue)
        }
    }

    // Internal private storage
    var commandPrefix = "~"
    var databaseDirectory: String?
    var ownerIds = [String]()

    private var development = false


    func setDevelopment(dev: Bool) {
        if development != dev {
            development = dev
            loadUserSettings()
        }
    }

    static let instance = Config()

    required init() {
        super.init()
        loadUserSettings()
    }

    func loadUserSettings()  {
        if let settings = NSUserDefaults.standardUserDefaults().objectForKey(settingsKey(development)) {
            LOG_DEBUG("Loaded settings: \(settings)")
            if let prefix = settings["commandPrefix"] as? String {
                self.commandPrefix = prefix
            }
            if let dbdir = settings["databaseDirectory"] as? String {
                self.databaseDirectory = dbdir
            }
            if let ids = settings["ownerIds"] as? [String] {
                self.ownerIds = ids
            }
        }
    }

    func saveUserSettings() {
        let settings = self.toDictionary(false)
            LOG_DEBUG("Saving settings: \(settings)")
        NSUserDefaults.standardUserDefaults().setObject(settings, forKey: settingsKey(development))
    }

    private func settingsKey(development: Bool = false) -> String {
        return development ? "SwiftBotSettingsDevelopment" : "SwiftBotSettings"
    }

}
