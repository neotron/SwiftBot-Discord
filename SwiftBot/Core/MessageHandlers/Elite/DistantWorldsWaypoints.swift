//
// Created by David Hedbor on 2/18/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI
import EVReflection

class DistantWorldsWaypoints: MessageHandler {
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
        self.handleWaypointCommand(wp, message: message);
        return true
    }

    override func handleCommand(command: String, args: [String], message: Message) -> Bool {
        return super.handleCommand(command, args: args, message: message)
    }
}

// MARK: Handle wp command

extension DistantWorldsWaypoints {

    private func handleWaypointCommand(wpString: String, message: Message) {
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
        let verbose = message.flags.contains(.Verbose)
        let wp = wps[wpnum]
        var output = [String]()
        output.append("**\(wp.name)**")
        if verbose {
            output.append("")
            output.append("`\(wp.desc)`")
            output.append("")
        }
        if wp.system != "TBA" {
            output.append("`Location`: **\(wp.system) \(wp.planet)** (*\(wp.baseCamp.name)*)")
        } else {
            output.append("`Location`: ** TBA ** (*\(wp.baseCamp.name)*)")
        }
        if wp.baseCamp.gravity > 0 && wp.baseCamp.coords.count >= 2 {
            var basecamp = "`Base Camp`: **\(wp.baseCamp.coords[0]) / \(wp.baseCamp.coords[1])** - \(wp.baseCamp.gravity) g  "
            if verbose {
                if let guide = wp.baseCamp.guide {
                    basecamp += guide
                }
            }
            output.append(basecamp)
        }
        if verbose {
            output.append("`Distance traveled:` \(wp.distance.traveled / 1000.0) kly")
            output.append("`Distance to next waypoint:` \(wp.distance.next / 1000.0) kly")
        }

        let reply = output.joinWithSeparator("\n")
        if verbose && !message.flags.contains(.Here) {
            message.replyToSender(reply)
        } else {
            message.replyToChannel(reply)
        }
    }
}


// MARK: JSON datafile loader

extension DistantWorldsWaypoints {

    private func loadDatabase() {
        let bundle = NSBundle(forClass: self.dynamicType)
        guard let path = bundle.pathForResource("DistantWorldsWaypoints", ofType: "json") else {
            LOG_ERROR("Failed to locate waypoints database.")
            return
        }
        guard let data = NSData(contentsOfFile: path), dataText = NSString(data: data, encoding: NSUTF8StringEncoding) else {
            LOG_ERROR("Failed to load and decode waypoints database.")
            return
        }
        EVReflection.setBundleIdentifier(SwiftBotMain)
        let db = Waypoints(json: dataText as String)
        //LOG_DEBUG("Loaded database \(db)")
        self.database = db
    }

}

class Waypoints: EVObject {
    var stages = [Stage]()
    var waypoints = [Waypoint]()
}

class Stage: EVObject {
    var waypoints = (start: 0, end: 0)
    var name = ""
    var image = ""


    // This is needed to convert waypoints to/from a tuple.
    override func propertyConverters() -> [(String?, (Any?) -> (), () -> Any?)] {
        return [("waypoints",
                {
                    guard let arr = $0 as? [Int] else {
                        return;
                    }
                    if arr.count != 2 {
                        LOG_ERROR("Invalid waypoints object: \(arr)")
                    } else {
                        self.waypoints = (arr[0], arr[1])
                    }
                },
                {
                    return [self.waypoints.start, self.waypoints.end]
                }
                )]
    }
}

class Distance: EVObject {
    var next = 0.0
    var traveled = 0.0
}

class BaseCamp: EVObject {
    var name = ""
    var coords = [0.0, 0.0]
    var gravity = 0.0
    var guide: String?
}

class Waypoint: EVObject {
    var name = ""
    var desc = ""
    var baseCamp = BaseCamp()
    var system = ""
    var planet = ""
    var distance = Distance()
    var keyEvent: String = ""

}
