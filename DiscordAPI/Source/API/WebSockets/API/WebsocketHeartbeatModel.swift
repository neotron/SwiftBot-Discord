//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import ObjectMapper

class WebsocketHeartbeatModel : MappableBase {
    var op = 1
    var timestamp: String?

    required init?(_ map: Map) {
        super.init(map)
    }

    override init() {
        timestamp = "\(Int(NSDate().timeIntervalSince1970*1000))"
        super.init()
    }

    override func mapping(map: Map) {
        op          <- map["op"]
        timestamp   <- map["d"]
    }

}
