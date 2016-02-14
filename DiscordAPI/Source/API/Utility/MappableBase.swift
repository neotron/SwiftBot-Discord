//
// Created by David Hedbor on 2/12/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import ObjectMapper

public class MappableBase : Mappable, CustomStringConvertible, CustomDebugStringConvertible {

    public required init?(_ map: Map) {
        self.mapping(map)
    }

    public init() {}

    public func mapping(map: Map) {    }


    private func formatDescription(prettyPrint: Bool) -> String {
        let json = Mapper().toJSONString(self, prettyPrint: prettyPrint)
        let cls = NSStringFromClass(self.dynamicType)
        return "\(cls)(\(json))"
    }
    public var description: String {
        return formatDescription(false)
    }

    public var debugDescription: String {
        return formatDescription(false)
    }

}
