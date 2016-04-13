//
// Created by David Hedbor on 2/12/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import Alamofire

public class LogoutRequest {

    func execute(callback:(Void)->Void) {
        guard let token = Registry.instance.token else {
            LOG_ERROR("Already logged out")
            return
        }
        Alamofire.request(.POST, Endpoints.Simple(.Logout), parameters: ["token": token], encoding: .JSON).responseData{
            (response: Response < NSData, NSError>)in
            Registry.instance.token = nil // reset token
            if let error = response.result.error {
                LOG_ERROR("Logout failed with error: \(error)")
            } else {
                LOG_INFO("Logout completed successfully.");
            }
            callback()
        }
    }
}
