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
    override func handlePrefix(_ prefix: String, command: String, args: [String], message: Message) -> Bool {
        let num = command.replacingOccurrences(of: prefix, with: "")
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

    override func handleCommand(_ command: String, args: [String], message: Message) -> Bool {
        var args = args
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
            _ = self.handlePrefix(command, command: "\(command)\(args.removeFirst())", args: args, message: message)
        }

        return true
    }
}

// MARK: Handle stage command
extension DistantWorldsWaypoints {
    fileprivate func handleStageCommand(_ stageStr: String, message: Message) {
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

    fileprivate func handleWaypointCommand(_ wpString: String, args: [String], message: Message) {
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
            terseOutput.append("`Waypoint \(wpnum)`: *\(wp.name)* - **\(wp.system)** on planet **\(wp.planet.name)**")
            verboseOutput.append("`Location`: **\(wp.system)** on planet **\(wp.planet.name)**")
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
            verboseOutput.append("\(events.joined(separator: "\n"))")
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
        let reply = verboseOutput.joined(separator: "\n")
        if verbose {
            message.replyToChannel(reply)
        } else {
            if !ignorePrivateMessage {
                message.replyToSender(reply)
            }
            if !message.isPrivateMessage {
                message.replyToChannel(terseOutput.joined(separator: "\n"))
            }
        }
    }
}


// MARK: JSON datafile loader

extension DistantWorldsWaypoints {

    fileprivate func loadDatabase() {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: "DistantWorldsWaypoints", ofType: "json") else {
            LOG_ERROR("Failed to locate waypoints database.")
            return
        }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)), let dataText = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            LOG_ERROR("Failed to load and decode waypoints database.")
            return
        }
        EVReflection.setBundleIdentifier(SwiftBotMain.self)
        let db = Waypoints(json: dataText as String)
        LOG_DEBUG("Loaded database (\(db.waypoints.count) waypoints)")
//        print(db.toJsonString());

        DistantWorldsWaypoints.database = db
    }

}

class WaypointRange: EVObject {
    var start = 0
    var end = 0
}

class Stage: EVObject {
    var waypoints = WaypointRange()
    var name = ""
    var image = ""
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
    var specialEvents: [String]?
}

class Waypoints: EVObject {
    var stages = [Stage]()
    var waypoints = [Waypoint]()
}
