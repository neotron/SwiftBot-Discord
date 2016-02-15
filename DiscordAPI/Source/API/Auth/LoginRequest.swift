//
// Created by David Hedbor on 2/12/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import ObjectMapper
import Alamofire
import AlamofireObjectMapper


public class LoginRequest {
    private let request: [String:String]
    public required init(_ email: String, password: String) {
        self.request = [
                "email": email,
                "password": password
        ]
    }

    public func execute(callback: ((LoginResponseModel?, NSError?)->Void)) {

        Alamofire.request(.POST, Endpoints.Simple(.Login), parameters: self.request, encoding: .JSON).responseObject {
            (response: Response<LoginResponseModel, NSError>) in
            Registry.instance.token = response.result.value?.token // save for future calls
            var error = response.result.error
            if error != nil {
                LOG_ERROR("Login failed with servererror: \(error!)")
            } else if let value = response.result.value {
                error = value.error
                if error != nil {
                    LOG_ERROR("Login failed with authentication error: \(error)")
                } else {
                    LOG_INFO("Login completed successfully.")
                    LOG_DEBUG("   => token = \(value.token!)");
                }
            }
            callback(response.result.value, error)
        }
    }
}


