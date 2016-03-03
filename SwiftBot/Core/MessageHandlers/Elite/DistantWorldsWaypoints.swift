//
// Created by David Hedbor on 2/18/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI
import EVReflection

class DistantWorldsWaypoints: MessageHandler {
    static var database: Waypoints?

    override init() {
        super.init()
        self.loadDatabase()
    }

    override var prefixes: [MessageCommand]? {
        return [("wp", nil),
                ("stage", nil)]
    }

    override var commands: [MessageCommand]? {
        return [("wp", "Retrieve Distant Worlds waypoints information. Usage: wp<number>, i.e wp9. Add -v flag for verbose output."),
                ("stage", "Return some information about the different stages in Distant Worlds Expedition.")]
    }
    override var commandGroup: String? {
        return "Elite: Dangerous"
    }
    override func handlePrefix(prefix: String, command: String, args: [String], message: Message) -> Bool {
        let num = command.stringByReplacingOccurrencesOfString(prefix, withString: "")
        switch prefix {
        case "wp":
            self.handleWaypointCommand(num, args: args, message: message)
        case "stage":
            self.handleStageCommand(num, message: message)
        default:
            return false
        }
        return true
    }

    override func handleCommand(command: String, var args: [String], message: Message) -> Bool {
        switch command {
        case "wp":
            if args.count == 0 || message.flags.contains(.Help) {
                message.replyToChannel(self.commands![0].h!)
            }
        case "stage":
            if args.count == 0 || message.flags.contains(.Help) {
                message.replyToChannel(self.commands![1].h!)
            }
        default:
            return false
        }
        if args.count > 0 {
            self.handlePrefix(command, command: "\(command)\(args.removeFirst())", args: args, message: message)
        }

        return true
    }
}

// MARK: Handle stage command
extension DistantWorldsWaypoints {
    private func handleStageCommand(stageStr: String, message: Message) {
        guard var stage = Int(stageStr) else {
            message.replyToChannel("Waypoint \(stageStr) is not an integer.")
            return
        }
        guard let stages = DistantWorldsWaypoints.database?.stages else {
            message.replyToChannel("Failed to load stage database, sorry.")
            return
        }
        stage -= 1
        if stage < 0 || stage >= stages.count {
            message.replyToChannel("Waypoint \(stageStr) is not a valid waypoint (use 1-\(stages.count)).")
        } else {
            let st = stages[stage]
            message.replyToChannel("**Stage \(stageStr): \(st.name)**, includes waypoints \(st.waypoints.start) to \(st.waypoints.end).\n\(st.image)")
        }
    }
}

// MARK: Handle wp command

extension DistantWorldsWaypoints {

    private func handleWaypointCommand(wpString: String, args: [String], message: Message) {
        guard let wpnum = Int(wpString) else {
            message.replyToChannel("Waypoint \(wpString) is not an integer.")
            return
        }
        guard let wps = DistantWorldsWaypoints.database?.waypoints else {
            message.replyToChannel("Failed to load waypoint database, sorry.")
            return
        }

        if wpnum < 0 || wpnum >= wps.count {
            message.replyToChannel("Waypoint \(wpnum) is not a valid waypoint (use 1-\(wps.count-1)).");
            return
        }

        let verbose = message.flags.contains(.Verbose)
        let wp = wps[wpnum]
        var verboseOutput = [String]()
        verboseOutput.append("`Waypoint \(wpnum)`: **\(wp.name)**")
        verboseOutput.append("")
        verboseOutput.append("*\(wp.desc)*")
        verboseOutput.append("")
        let hasBaseCamp = wp.system != "TBA"
        var terseOutput = [String]()
        if hasBaseCamp {
            terseOutput.append("`Waypoint \(wpnum)`: *\(wp.name)* - **\(wp.system) \(wp.planet.name)**")
            verboseOutput.append("`Location`: **\(wp.system) \(wp.planet.name)**")
            if wp.planet.gravity > 0 && wp.baseCamp.coords.count >= 2 {
                var basecamp = "`Base Camp`: *\(wp.baseCamp.name)* - **\(wp.baseCamp.coords[0]) / \(wp.baseCamp.coords[1])** (\(wp.planet.gravity) g)  "
                terseOutput.append(basecamp)
                if let guide = wp.baseCamp.guide {
                    basecamp += guide
                }
                verboseOutput.append(basecamp)

            }
        } else {
            verboseOutput.append("`Location`: ** TBA ** (*\(wp.baseCamp.name)*)")
            terseOutput.append("`Waypoint \(wpnum)`: *\(wp.name)* - **TBA** - *\(wp.baseCamp.name)*")
        }
        verboseOutput.append("`Distance traveled:` \(wp.distance.traveled / 1000.0) kly")
        verboseOutput.append("`Distance to next waypoint:` \(wp.distance.next / 1000.0) kly")

        if let events = wp.events {
            verboseOutput.append("\(events.joinWithSeparator("\n"))")
            terseOutput.append(verboseOutput.last!)
        }
        var ignorePrivateMessage = false
        if hasBaseCamp {
            var doubles = [Double]()
            for arg in args {
                if let dbl = Double(arg) {
                    doubles.append(dbl)
                    if (doubles.count == 2) {
                        break;
                    }
                }
            }
            if doubles.count == 2 {

                ignorePrivateMessage = true
                let end = PlanetaryMath.LatLong(wp.baseCamp.coords[0], wp.baseCamp.coords[1])
                let start = PlanetaryMath.LatLong(doubles[0], doubles[1])
                let result = PlanetaryMath.calculateBearingAndDistance(start: start, end:end, radius: wp.planet.radius)
                let distance = PlanetaryMath.distanceFor(result.distance)
                verboseOutput.append(String(format: "\n`To get to the base camp from \(String(latlong: start)) head in bearing %.1f°\(distance).`", result.bearing))
                terseOutput = [terseOutput[0]]
                terseOutput.append(String(format: "To get to the base camp at `\(String(latlong: end))` from `\(String(latlong: start))` head in bearing **%.1f°**\(distance).", result.bearing))
            }
        }
        let reply = verboseOutput.joinWithSeparator("\n")
        if verbose {
            message.replyToChannel(reply)
        } else {
            if !ignorePrivateMessage {
                message.replyToSender(reply)
            }
            if !message.isPrivateMessage {
                message.replyToChannel(terseOutput.joinWithSeparator("\n"))
            }
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
        LOG_DEBUG("Loaded database (\(db.waypoints.count) waypoints)")
        LOG_DEBUG("\n****\n")
        print(db.toJsonString());
        LOG_DEBUG("\n****\n")

        DistantWorldsWaypoints.database = db
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
    var guide: String?
}

class Planet : EVObject {
    var name = ""
    var gravity = 0.0
    var radius = 0.0
}

class Waypoint: EVObject {
    var name = ""
    var desc = ""
    var baseCamp = BaseCamp()
    var system = ""
    var planet = Planet()
    var distance = Distance()
    var events: [String]?
    var keyEvent: String?
}
