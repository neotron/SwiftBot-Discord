//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Some functionality especially for Elite: Dangerous to calculcate gravity, core route distances tc.
// Limited functionality outside of E:D :-)

import Foundation
import DiscordAPI

class ScienceMessageHandler : MessageHandler {
    private let densitySigmaArray : [(String,Double,Double,Double,Double)] = [
            ("IW",1.06E+12,1.84E+12,2.62E+12,3.40E+12),
            ("RIW",2.25E+12,2.82E+12,3.38E+12,3.95E+12),
            ("RW",2.94E+12,3.77E+12,4.60E+12,5.43E+12),
            ("HMC",1.21E+12,4.60E+12,8.00E+12,1.14E+13),
            ("MR",1.47E+12,7.99E+12,1.45E+13,2.10E+13),
            ("WW",1.51E+12,4.24E+12,6.97E+12,9.70E+12),
            ("ELW",4.87E+12,5.65E+12,6.43E+12,7.21E+12),
            ("AW",4.23E+11,3.50E+12,6.59E+12,9.67E+12)
    ]


    var prefixes: [String]? {
        return nil
    }
    var commands: [String]? {
        return ["g", "route"]
    }
    func handlePrefix(prefix: String, command: String, args: [String], message: MessageModel, event: MessageEventType, completeCallback: (responseMessage:String?, privateMessage:Bool?) -> (Void)) -> Bool {
        return false
    }

    func handleCommand(command: String, args: [String], message: MessageModel, event: MessageEventType, completeCallback: (responseMessage:String?, privateMessage:Bool?) -> (Void)) -> Bool {
        switch(command) {
        case "g":
            handleGravity(args, callback: completeCallback)
        case "route":
            handleRoute(args, callback: completeCallback)
        default:
            return false
        }
        return true
    }

    private func handleGravity(args: [String], callback: (responseMessage:String?, privateMessage:Bool?) -> (Void)) {
        if args.count < 2 {
            callback(responseMessage: "Missing arguments. Expected: <EarthMasses> <Radius in KM>", privateMessage: false)
            return
        }

        guard let planetMass = Double(args[0]), planetRadius = Double(args[1]) else {
            callback(responseMessage: "Error: earth masses and planet radius parameters should be numbers.", privateMessage: false)
            return
        }

        let G = 6.67*pow(10,-11)
        let earthMass = 5.98*pow(10, 24)
        let earthRadius = 6378000.0
        let baseG = G * earthMass / pow(earthRadius, 2.0)
        let planetG = (G*planetMass*earthMass/pow(planetRadius*1000, 2.0))
        let planetDensity = planetMass*earthMass/(4.0/3.0*M_PI*pow(planetRadius, 3))
        var planetM2Str: String
        var planetGStr : String
        if planetG > 1000 {
            planetM2Str = String(format: "%.2e", planetG)
            planetGStr = String(format: "%.2e", planetG/baseG)
        } else {
            planetM2Str = String(format: "%.2f", planetG)
            planetGStr = String(format: "%.2f", planetG / baseG)
        }
        var maybeTypes = [String]()
        var likelyTypes = [String]()
        for row in densitySigmaArray {
            if planetDensity > row.2 && planetDensity < row.3 {
                likelyTypes.append(row.0)
            } else if planetDensity > row.1 && planetDensity < row.4 {
                maybeTypes.append(row.0)
            }
        }
        var densityString = ""
        if likelyTypes.count > 0 {
            densityString += ". **Likely**: "+likelyTypes.sort().joinWithSeparator(", ")
        }
        if maybeTypes.count > 0 {
            densityString += ". **Possible**: "+maybeTypes.sort().joinWithSeparator(", ")
        }
        let planetDensityStr = String(format: "%.2e", planetDensity)

        callback(responseMessage: "The gravity for a planet with \(planetMass) Earth Masses and a radius of \(planetRadius) km is **\(planetM2Str)** m/s^2 or **\(planetGStr)** g. It has a density of **\(planetDensityStr)** kg/km^3\(densityString)", privateMessage: false)
    }

    private func handleRoute(args: [String], callback: (responseMessage:String?, privateMessage:Bool?) -> (Void)) {
        let failure = false
        var maxDistance = 1000.0
        if args.count < 2 {
            callback(responseMessage: "Missing arguments. Expected: <JumpRange> <SgrA* distance in kly> [optional max plot in ly]", privateMessage: false)
            return
        }

        guard let jumpRange = Double(args[0]), distance = Double(args[1]) else {
            callback(responseMessage: "Error: jump range and distance parameters should be numbers.", privateMessage: false)
            return
        }

        if args.count > 2 {
            if let optMaxDistance = Double(args[2]) {
                maxDistance = optMaxDistance
            }
        }

        let N = floor(maxDistance / jumpRange)
        let M = N * jumpRange
        callback(responseMessage: String(format: "Estimated plot range should be around %.2f ly", (M - ((N / 4) + (distance * 2)))), privateMessage: false)
    }

}
