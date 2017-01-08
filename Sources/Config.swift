//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI
import EVReflection

class Config: EVObject {
    static let CONFIG_CHANGE_KEY = "ApplicationModeChange"

    // Instance accessible read-only settings.
    static var commandPrefix: String {
        get {
            return instance.commandPrefix
        }
        set {
            instance.commandPrefix = newValue
            instance.saveUserSettings()
        }
    }
    static var databaseDirectory: String? {
        get {
            return instance.databaseDirectory
        } set {
            instance.databaseDirectory = newValue
            CoreDataManager.instance.reopenDatabase()
            instance.saveUserSettings()
        }
    }
    static var ownerIds: Set<String> {
        get {
            return Set(instance.ownerIds)
        }
        set {
            instance.ownerIds = Array(newValue)
            instance.saveUserSettings()

        }
    }
    static var development: Bool {
        get {
            return instance.development
        }
        set {
            if newValue != instance.development {
                instance.development = newValue
                instance.loadUserSettings()
            }
        }
    }

    // Internal private storage
    var commandPrefix = "~"
    var databaseDirectory: String?
    var ownerIds = [String]()

    var development = false {
        didSet {
            let center = NotificationCenter.default
            center.post(Notification(name: Notification.Name(rawValue: Config.CONFIG_CHANGE_KEY), object: nil))
        }
    }

    fileprivate static let instance = Config()

    required init() {
        super.init()
        loadUserSettings()
    }

    fileprivate func loadUserSettings()  {
        if let settings = UserDefaults.standard.object(forKey: settingsKey(development)) as? [String:Any]{
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

    fileprivate func saveUserSettings() {
        let settings : NSMutableDictionary = self.toDictionary().mutableCopy() as! NSMutableDictionary
        for (key, value) in settings {
            if let _ = value as? NSNull {
                settings.removeObject(forKey: key)
            }
        }
        LOG_DEBUG("Saving settings: \(settings)")
        UserDefaults.standard.set(settings, forKey: settingsKey(development))
    }

    fileprivate func settingsKey(_ development: Bool = false) -> String {
        return development ? "SwiftBotSettingsDevelopment" : "SwiftBotSettings"
    }

}
