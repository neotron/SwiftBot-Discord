//
// Created by David Hedbor on 2/12/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import ObjectMapper

public class LoginResponseModel: MappableBase {
    public var token : String?
    public var emailError : String?
    public var passwordError : String?

    public var error: NSError? {
        if(token == nil) {
            var errorString = "LoginFailure"
            var userInfo = [String:String]()
            userInfo[NSLocalizedDescriptionKey] = "Login failed due to authentication failure."
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = "Verify your user name and password."

            if(emailError != nil) {
                userInfo["email"] = emailError
            }
            if(passwordError != nil) {
                userInfo["password"] = passwordError
            }

            return NSError(domain: errorString, code: -1, userInfo: userInfo);
        }
        return nil;
    }

    public override func mapping(map: Map) {
        token <- map["token"]
        emailError <- map["email"]
        passwordError <- map["password"]
    }


}
