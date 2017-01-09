//
// Created by David Hedbor on 2/25/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import SwiftDiscord
import Mapper

// {"msgnum":100,"msg":"OK","system":"Phipoea DD-F c26-1311","firstDiscover":false,"date":"2016-02-25 06:44:54"}

struct CommanderPositionModel: Mappable {
    let msg: String
    let msgnum: Int
    let system: String?
    let firstDiscover: Bool
    let date: String?


    init(map: Mapper) throws {
        try msg = map.from("msg")
        try msgnum = map.from("msgnum")
        system = map.optionalFrom("system")
        firstDiscover = map.optionalFrom("firstDiscover") ?? false
        date = map.optionalFrom("date")
    }
}

struct CoordModel: Mappable {
    let x: Double
    let y: Double
    let z: Double

    init(map: Mapper) throws {
        try x = map.from("x")
        try y = map.from("y")
        try z = map.from("z")
    }
    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

struct SystemModel: Mappable {
    let name: String
    let coords: CoordModel?

    init(map: Mapper) throws {
        try name = map.from("name")
        coords = map.optionalFrom("coords")
    }
    init(name: String, coords: CoordModel?) {
        self.name = name
        self.coords = coords
    }
}

class EDSMMessageHandler: MessageHandler {
    fileprivate let aliases = [
            "jaques": "Colonia",
            "jaques station": "Colonia",
    ]

    override var commands: [MessageCommand]? {
        return [("loc", "Try to get a commanders location from EDSM. Syntax: loc <commander name>"),
                ("dist", "Calculate distance between two systems. Syntax: dist <system> -> <system> (i.e: `dist Sol -> Sagittarius A*`)")
        ]
    }
    override var commandGroup: String? {
        return "EDSM Api Queries"
    }
    override func handleCommand(_ command: String, args: [String], message: Message) -> Bool {
        switch (command) {
        case "loc":
            handleLocationLookup(args.joined(separator: " "), message: message)
        case "dist":
            var systems = args.joined(separator: " ").components(separatedBy: "->").map {
                $0.trimmingCharacters(in: CharacterSet.whitespaces)
            }
            if (systems.count == 1) {
                systems.append("Sol")
            }
           handleDistance(systems, message: message)
        default:
            return false
        }
        return true
    }

    fileprivate func handleDistance( _ systems: [String], message: Message) {
        if systems.count != 2 {
            message.replyToChannel("Invalid syntax. Expected: `\(Config.commandPrefix)dist System Name -> System 2 Name`")
            return
        }
        var systemCoords = [SystemModel]()
        let calcDist = {
            (model: SystemModel) in
            systemCoords.append(model)
            if (systemCoords.count == 2) {
                self.calculateDistance(systemCoords, message: message)
            }
        }
        for var systemName in systems {
            var waypointName: String?
            if let alias = self.aliases[systemName.lowercased()] {
                waypointName = "\(systemName) (\(alias))"
                systemName = alias
            }
            let parts = systemName.components(separatedBy: " ")
            if (parts.count == 3) {
                if let x = Double(parts[0]), let y = Double(parts[1]), let z = Double(parts[2]) {
                    let system = SystemModel(name: "(x: \(x), y: \(y), z: \(z))", coords: CoordModel(x: x, y: y, z: z))
                    calcDist(system)
                    continue
                }
            }
            if (parts.count == 1) {
                if let wp = Int(parts[0]) {
                    guard let wps = DistantWorldsWaypoints.database?.waypoints else {
                        message.replyToChannel("Failed to load waypoint database, sorry.")
                        return
                    }
                    if wp < 0 || wp >= wps.count {
                        message.replyToChannel("Waypoint \(wp) is not valid.")
                        return
                    }
                    if wps[wp].system == "TBA" {
                        message.replyToChannel("Waypoint \(wp)'s system is not known yet.")
                        return
                    }
                    systemName = wps[wp].system
                    waypointName = "Waypoint \(wp) (\(systemName))"

                }
            }

            getSystemCoords(systemName, message: message) {
                (system: SystemModel?) in
                if let system = system {
                    if let name = waypointName {
                        calcDist(SystemModel(name: name, coords: system.coords))
                    } else {
                        calcDist(system)
                    }
                    return
                }
                // TODO: FIXME
#if false
                Alamofire.request("http://www.edsm.net/api-logs-v1/get-position/", parameters: ["commanderName": systemName]).responseObject {
                    (response: DataResponse<CommanderPositionModel>) in
                    guard let location = response.result.value else {
                        message.replyToChannel("Failed to complete request.")
                        LOG_ERROR("Get Position api failed with error \(response.result.error)")
                        return
                    }
                    
                    if let system = location.system {
                        self.getSystemCoords(system, message: message) {
                            (model: SystemModel?) in
                            if let system = model {
                                system.name = "\(systemName) (\(system.name))"
                                calcDist(system)
                                return
                            } else {
                                self.reportNotTrilaterated(systemName, message: message)
                            }
                        }
                    } else {
                        self.reportNotTrilaterated(systemName, message: message)
                    }
                }
#endif
            message.replyToChannel("API disabled presently.")
            }
        }
    }

    fileprivate func getSystemCoords(_ systemName: String, message: Message, callback: @escaping (SystemModel?) -> Void) {
        #if false
        Alamofire.request("http://www.edsm.net/api-v1/system",
                          parameters: ["systemName": systemName,
                                       "coords": "1"]).responseObject {
            (response: DataResponse<SystemModel>) in
            if let system = response.result.value {
                guard let _ = system.coords else {
                    if system.name != "" {
                        self.reportNotTrilaterated(systemName, message: message)
                    } else {
                        callback(nil)
                    }
                    return
                }
                callback(system)
            } else {
                callback(nil)
            }
        }
        #endif
        callback(nil)
    }

    fileprivate func reportNotTrilaterated(_ systemName: String, message: Message) {
        message.replyToChannel("\(systemName) has not been trilaterated.")
    }

    fileprivate func calculateDistance(_ systems: [SystemModel], message: Message) {
        guard let c1 = systems[0].coords, let c2 = systems[1].coords else {
            message.replyToChannel("Couldn't get coordinates for both systems.")
            return
        }

        let sq2 = {
            (a: Double, b: Double) -> Double in
            let val = a - b
            return val * val
        }
        let dist = sqrt(sq2(c1.x, c2.x) + sq2(c1.y, c2.y) + sq2(c1.z, c2.z));
        message.replyToChannel(String(format: "Distance between \(systems[0].name) and \(systems[1].name) is %.2f ly", dist))

    }

    fileprivate func handleLocationLookup(_ commander: String, message: Message) {
        #if false
        Alamofire.request("http://www.edsm.net/api-logs-v1/get-position/", parameters: ["commanderName": commander]).responseObject {
            (response: DataResponse<CommanderPositionModel>) in
            guard let location = response.result.value else {
                message.replyToChannel("Failed to complete request.")
                LOG_ERROR("Get Position api failed with error \(response.result.error)")
                return
            }
            if let system = location.system {
                var output = "\(commander) was last seen in \(system)";
                if let date = location.date {
                    output += " at \(date)"
                }
                message.replyToChannel("\(output).")
            } else {
                switch location.msgnum {
                case 100:
                    message.replyToChannel("I have no idea where \(commander) is - perhaps they aren't sharing their position?")
                case 203:
                    message.replyToChannel("There's no known commander by the name \(commander).");
                default:
                    message.replyToChannel("Some error happened.");
                }
            }
        }
#endif
        message.replyToChannel("Currently disabled.")
    }

}
