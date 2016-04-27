//
// Created by David Hedbor on 2/20/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI
import Locksmith

@objc class DiscordAccount: NSObject, ReadableSecureStorable, CreateableSecureStorable,
        DeleteableSecureStorable, GenericPasswordSecureStorable {

    var token = ""

    override init() {
        super.init()
        let result = self.readFromSecureStore()
        if let data = result?.data {
            self.token = data["token"] as! String
        }
    }

    init(token: String) {
        self.token = token
        super.init()
    }

    let service = "Discord"
    var account: String {
        return "SwiftBotLogin"
    }

    var data: [String:AnyObject] {
        return [
                "token": token
        ]
    }
}

@objc class AuthenticationManager: NSObject {
    static var instance = AuthenticationManager()

    func updateCredentialsWithToken(token: String) -> Bool {
        let account = DiscordAccount(token: token)
        do {
            try account.createInSecureStore()
        } catch LocksmithError.Duplicate {
            do {
                try account.updateInSecureStore()
            } catch {
                LOG_ERROR("Failed to update login information in secure storage: \(error)")
                return false
            }
        } catch {
            LOG_ERROR("Failed to store new login information in secure storage: \(error)")
            return false
        }
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "DiscordAuthenticationChanged", object: nil, userInfo: ["token": token]))
        return true
    }
}
