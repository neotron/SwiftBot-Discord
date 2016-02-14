//
// Created by David Hedbor on 2/12/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import ObjectMapper

public class UserModel : MappableBase {
    public var avatar: String?
    public var discriminator: String?
    public var id: String?
    public var username: String?
    public var email: String?
    public var verified: Bool?


    public override func mapping(map: Map) {
        username        <- map["username"]
        avatar          <- map["avatar"]
        discriminator   <- map["discriminator"]
        id              <- map["id"]
        email           <- map["email"]
        verified        <- map["verified"]
    }

}
