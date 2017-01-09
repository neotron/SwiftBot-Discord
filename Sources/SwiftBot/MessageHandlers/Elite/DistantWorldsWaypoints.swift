//
// Created by David Hedbor on 2/18/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import SwiftDiscord
import Mapper

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
            message.replyToChannel("Waypoint \(wpnum) is not a valid waypoint (use 1-\(wps.count - 1)).");
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
                    if(doubles.count == 2) {
                        break;
                    }
                }
            }
            if doubles.count == 2 {

                ignorePrivateMessage = true
                let end = PlanetaryMath.LatLong(wp.baseCamp.coords[0], wp.baseCamp.coords[1])
                let start = PlanetaryMath.LatLong(doubles[0], doubles[1])
                let result = PlanetaryMath.calculateBearingAndDistance(start: start, end: end, radius: wp.planet.radius)
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
        guard let path = Config.databaseDirectory else {
            LOG_ERROR("Failed to locate waypoints database.")
            return
        }
        let dwePath = "\(path)/DistantWorldsWaypoints.json"
        guard let json = JSON.from(file: dwePath) else {
            LOG_ERROR("Failed to load and decode waypoints database: \(dwePath)")
            return
        }
        do {
            let db = try Waypoints(map: Mapper(JSON: json))
            LOG_DEBUG("Loaded database (\(db.waypoints.count) waypoints)")
            DistantWorldsWaypoints.database = db
        } catch {
            LOG_ERROR("Failed to json map waypoints database: \(error)")
            return
        }
    }

}

struct WaypointRange: Mappable {
    let start: Int
    let end: Int

    init(map: Mapper) throws {
        try start = map.from("start")
        try end = map.from("end")
    }
}

struct Stage: Mappable {
    let waypoints: WaypointRange
    let name: String
    let image: String

    init(map: Mapper) throws {
        try waypoints = map.from("waypoints")
        try name = map.from("name")
        image = map.optionalFrom("image") ?? ""
    }
}

struct Distance: Mappable {
    let next: Double
    let traveled: Double

    init(map: Mapper) throws {
        try next = map.from("next")
        try traveled = map.from("traveled")
    }

}

struct BaseCamp: Mappable {
    let name: String
    let coords: [Double]
    let guide: String?

    init(map: Mapper) throws {
        try name = map.from("name")
        coords = map.optionalFrom("coords") ?? [0.0, 0.0]
        guide = map.optionalFrom("guide")
    }
}

struct Planet: Mappable {
    let name: String
    let gravity: Double
    let radius: Double
    init() {
        name = ""
        gravity = 0.0
        radius = 0.0
    }
    init(map: Mapper) throws {
        try name = map.from("name")
        gravity = map.optionalFrom("gravity") ?? 0.0
        radius = map.optionalFrom("radius") ?? 0.0
    }
}

struct Waypoint: Mappable {
    let name: String
    let desc: String
    let baseCamp: BaseCamp
    let system: String
    let planet: Planet
    let distance: Distance
    let events: [String]?
    let keyEvent: String?
    let specialEvents: [String]?

    init(map: Mapper) throws {
        try name = map.from("name")
        try desc = map.from("desc")
        try baseCamp = map.from("baseCamp")
        system = map.optionalFrom("system") ?? ""
        planet = map.optionalFrom("planet") ?? Planet()
        distance = try map.from("distance")
        events = map.optionalFrom("events")
        keyEvent = map.optionalFrom("keyEvent")
        specialEvents = map.optionalFrom("specialEvents")
    }
}

struct Waypoints: Mappable {
    let stages: [Stage]
    let waypoints: [Waypoint]

    init(map: Mapper) throws {
        stages = try map.from("stages")
        waypoints = try map.from("waypoints")
    }
}
