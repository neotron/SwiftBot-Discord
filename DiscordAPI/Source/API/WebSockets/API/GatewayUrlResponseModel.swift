//
// Created by David Hedbor on 2/12/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import ObjectMapper

public class GatewayUrlResponseModel : MappableBase {
    public var url: String?

    public override func mapping(map: Map) {
        url <- map["url"]
    }
}
