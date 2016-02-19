//
// Created by David Hedbor on 2/18/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI
import ObjectMapper

class DistantWorldsWaypoints : MessageHandler {
    private var database: Waypoints?

    override init() {
        super.init()
        self.loadDatabase()
    }

    override var prefixes: [MessageCommand]? {
        return [("wp", nil)]
    }

    override var commands: [MessageCommand]? {
        return [("wp", "Retrieve Distant Worlds waypoints information. Usage: wp<number>, i.e wp9. Add -v flag for verbose output.")]
    }
    override var commandGroup: String? {
        return "Elite: Dangerous"
    }
    override func handlePrefix(prefix: String, command: String, args: [String], message: Message) -> Bool {
        let wp = command.stringByReplacingOccurrencesOfString(prefix, withString: "")
        let verbose = args.contains("-v")
        self.handleWaypointCommand(wp, verbose: verbose, message: message);
        return true
    }

    override func handleCommand(command: String, args: [String], message: Message) -> Bool {
        return super.handleCommand(command, args: args, message: message)
    }
}

// MARK: Handle wp command
extension DistantWorldsWaypoints {

    private func handleWaypointCommand(wpString: String, verbose: Bool, message: Message) {
        guard let wpnum = Int(wpString) else {
            message.replyToChannel("Waypoint \(wpString) is not an integer.")
            return
        }
        guard let wps = self.database?.waypoints else {
            message.replyToChannel("Failed to load waypoint database, sorry.")
            return
        }

        if wpnum < 0 || wpnum >= wps.count {
            message.replyToChannel("Waypoint \(wpnum) is not a valid waypoint (use 1-\(wps.count)).");
            return
        }

        let wp = wps[wpnum]
        var output = [String]()
        output.append("**\(wp.name)**")
        if verbose {
            output.append("")
            output.append("`\(wp.desc)`")
            output.append("")
        }
        if wp.system != "TBA" {
            output.append("`Location`: **\(wp.system) \(wp.planet)** (*\(wp.baseCampName)*)")
        } else {
            output.append("`Location`: ** TBA ** (*\(wp.baseCampName)*)")
        }
        if wp.baseCampGravity > 0 && wp.baseCampCoords.count >= 2 {
            var basecamp = "`Base Camp`: **\(wp.baseCampCoords[0]) / \(wp.baseCampCoords[1])** - \(wp.baseCampGravity) g  "
            if(verbose) {
                if let guide = wp.baseCampGuide {
                    basecamp += guide
                }
            }
            output.append(basecamp)
        }
        if verbose {
            output.append("`Distance traveled:` \(wp.distanceTraveled / 1000.0) kly")
            output.append("`Distance to next waypoint:` \(wp.distanceToNext / 1000.0) kly")
        }

        let reply = output.joinWithSeparator("\n")
        if(verbose) {
            message.replyToSender(reply)
        } else {
            message.replyToChannel(reply)
        }
    }
}


// MARK: JSON datafile loader
extension  DistantWorldsWaypoints {

    private func loadDatabase() {
        let bundle = NSBundle(forClass: self.dynamicType)
        guard let path = bundle.pathForResource("DistantWorldWaypoints", ofType: "json") else {
            LOG_ERROR("Failed to locate waypoints database.")
            return
        }
        guard let data = NSData(contentsOfFile: path), dataText = NSString(data: data, encoding: NSUTF8StringEncoding) else {
            LOG_ERROR("Failed to load and decode waypoints database.")
            return
        }
        guard let db = Mapper<Waypoints>().map(dataText) else {
            LOG_ERROR("Failed to load database due to formatting issues.")
            return
        }
        self.database = db
    }

    private class Waypoints : MappableBase {
        var stages: [Stage]?
        var waypoints: [Waypoint]?

        override func mapping(map: Map) {
            stages <- map["stages"]
            waypoints <- map["waypoints"]
        }
    }

    private class Stage: MappableBase {
        var waypoints: (start: Int, end: Int) {
            guard let wp = _waypoints else {
                return (0, 0)
            }
            if wp.count >= 2 {
                return (wp[0], wp[1])
            }
            return (0, 0)
        }
        var name = ""
        var image = ""

        private var _waypoints: [Int]?

        override func mapping(map: Map) {
            name <- map["name"]
            image <- map["image"]
            _waypoints <- map["waypoints"]

        }

    }

    private class Waypoint: MappableBase {
        var name: String { return _name! }
        var desc: String { return _desc! }
        var baseCampName: String { return _baseCampName! }
        var baseCampCoords: [Double] { return _baseCampCoords! }
        var baseCampGravity: Double { return _baseCampGravity! }
        var baseCampGuide: String? { return _baseCampGuide }
        var system: String { return _system! }
        var planet: String { return _planet! }
        var distanceTraveled: Double { return _distanceTraveled! }
        var distanceToNext: Double { return _distanceToNext! }
        var keyEvent: String? { return _keyEvent }


        private var _name: String?
        private var _desc: String?
        private var _baseCampName: String?
        private var _baseCampCoords: [Double]?
        private var _baseCampGravity: Double?
        private var _baseCampGuide: String?
        private var _system: String?
        private var _planet: String?
        private var _distanceTraveled: Double?
        private var _distanceToNext: Double?
        private var _keyEvent: String?

        override func mapping(map: Map) {
            _name <- map["name"]
            _desc <- map["desc"]
            _baseCampName    <- map["base_camp.name"]
            _baseCampCoords  <- map["base_camp.coords"]
            _baseCampGravity <- map["base_camp.gravity"]
            _baseCampGuide   <- map["base_camp.guide"]
            _system <- map["system"]
            _planet <- map["planet"]
            _distanceTraveled <- map["distance.traveled"]
            _distanceToNext   <- map["distance.next"]
            _keyEvent         <- map["key_event"]
        }

    }
}
