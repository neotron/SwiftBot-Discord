//
// Created by David Hedbor on 2/20/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI
import Locksmith

@objc class DiscordAccount: NSObject, ReadableSecureStorable, CreateableSecureStorable,
        DeleteableSecureStorable, GenericPasswordSecureStorable {

    var email = ""
    var password = ""
    var token = ""

    override init() {
        super.init()
        let result = self.readFromSecureStore()
        if let data = result?.data {
            self.email = data["email"] as! String
            self.password = data["password"] as! String
            self.token = data["token"] as! String
        }
    }

    init(email: String, password: String, token: String) {
        self.email = email
        self.password = password
        self.token = token
        super.init()
    }

    let service = "Discord"
    var account: String {
        return "SwiftBotLogin"
    }

    var data: [String:AnyObject] {
        return [
                "email": email,
                "password": password,
                "token": token
        ]
    }
}

@objc class AuthenticationManager: NSObject {
    static var instance = AuthenticationManager()

    func validateCredentialsWithEmail(email: String, password: String, callback: (token:String?, error:NSError?) -> Void) {
        let request = LoginRequest(email, password: password)
        request.execute({
            (response: LoginResponseModel?, error: NSError?) in
            if let token = response?.token {
                callback(token: token, error: nil)
                LOG_INFO("Validated login for email \(email)")
            } else {
                callback(token: nil, error: error)
                LOG_ERROR("Login error \(error)")
            }
        })
    }

    func updateCredentialsWithEmail(email: String, password: String, token: String) -> Bool {
        let account = DiscordAccount(email: email, password: password, token: token)
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
