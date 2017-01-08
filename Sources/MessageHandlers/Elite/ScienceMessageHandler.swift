//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Some functionality especially for Elite: Dangerous to calculcate gravity, core route distances tc.
// Limited functionality outside of E:D :-)

import Foundation
import DiscordAPI

class ScienceMessageHandler: MessageHandler {

    override var commandGroup: String? {
        return "Elite: Dangerous"
    }

    fileprivate let densitySigmaArray: [(String, Double, Double, Double, Double)] = [ // in SI units of kg/m^3
            ("IW", 1.06E+3, 1.84E+3, 2.62E+3, 3.40E+3),
            ("RIW", 2.25E+3, 2.82E+3, 3.38E+3, 3.95E+3),
            ("RW", 2.94E+3, 3.77E+3, 4.60E+3, 5.43E+3),
            ("HMC", 1.21E+3, 4.60E+3, 8.00E+3, 1.14E+4),
            ("MR", 1.47E+3, 7.99E+3, 1.45E+4, 2.10E+4),
            ("WW", 1.51E+3, 4.24E+3, 6.97E+3, 9.70E+3),
            ("ELW", 4.87E+3, 5.65E+3, 6.43E+3, 7.21E+3),
            ("AW", 4.23E+2, 3.50E+3, 6.59E+3, 9.67E+3)
    ]

    override var commands: [MessageCommand]? {
        return [
                ("bearing", "Calculate bearing and optional distance between two planetary coordiantes. Args: <lat1> <lon1> <lat2> <lon2> [planet radius in km]"),
                ("g", "Calculate gravity for a planet. Arguments: <Earth masses> <radius in km>"),
                ("route", "Calculate optimal core routing distance. Arguments: <jump range> <kly to Sgr A*> [optional: max route length in ly]"),
                ("kly/hr", "Calculate max kly travelled per hour. Arguments: <jump range> [optional: time per jump in seconds (default 45s)]")
        ]
    }

    override func handleCommand(_ command: String, args: [String], message: Message) -> Bool {
        switch (command) {
        case "g":
            handleGravity(args, message: message)
        case "route":
            handleRoute(args, message: message)
        case "kly/hr":
            handleKlyPerHour(args, message: message)
        case "bearing":
            handleBearingAndDistance(args, message: message)
        default:
            return false
        }
        return true
    }

    fileprivate func handleBearingAndDistance(_ args: [String], message: Message) {
        var radius: Double?
        var start: PlanetaryMath.LatLong?
        var end: PlanetaryMath.LatLong?
        do {
            switch args.count {
            case 5 ... 100:
                radius = Double(args[4])
                fallthrough

            case 4:
                guard let lat1 = Double(args[0]), let lon1 = Double(args[1]), let lat2 = Double(args[2]), let lon2 = Double(args[3])  else {
                    message.replyToChannel("The coordinates must be a number (lat1 lon1 lat2 lon2 [optional radius in km]).")
                    return
                }
                start = (lat1, lon1)
                end = (lat2, lon2)
            default:
                message.replyToChannel("Not enough arguments. Expected 4-5 numbers (lat1 lon1 lat2 lon2 [optional radius in km]).")
                return
            }
        }
        if let start = start, let end = end {
            let result = PlanetaryMath.calculateBearingAndDistance(start: start, end: end, radius: radius)
            let distance = PlanetaryMath.distanceFor(result.distance)
            message.replyToChannel(String(format: "To get from \(String(latlong:start)) to \(String(latlong:end)) head in bearing %.1f°\(distance).", result.bearing))
        } else {
            message.replyToChannel("Couldn't parse start/end coordinates.")
        }
    }


    fileprivate func handleKlyPerHour(_ args: [String], message: Message) {
        if args.count < 1 {
            message.replyToChannel("Missing arguments. Expected: <jump range> [time per jump in seconds]")
            return
        }

        guard let jumpRange = Double(args[0]) else {
            message.replyToChannel("The jump range must be a number ( <jump range> [time per jump in seconds]).")
            return
        }

        var jumpTime = 45.0

        if args.count > 1 {
            if let optJumpTime = Double(args[1]) {
                jumpTime = optJumpTime
            }
        }
        let jumpsPerHour = 3600.0 / jumpTime
        let avgJump = jumpRange * 0.97
        let rangePerHour = round(jumpsPerHour * avgJump) // Random
        message.replyToChannel("Spending an average of *\(jumpTime)s* per system, with an average hop of *\(avgJump)* ly, 97% of *\(jumpRange)*, you can travel ** \(rangePerHour) ly / hour**.")
    }

    fileprivate func handleGravity(_ args: [String], message: Message) {
        if args.count < 2 {
            message.replyToChannel("Missing arguments. Expected: <EarthMasses> <Radius in km>")
            return
        }

        guard let planetMass = Double(args[0]), let planetRadius = Double(args[1]) else {
            message.replyToChannel("The arguments must be numbers. Expected: <EarthMasses> <Radius in km>")
            return
        }

        let G = 6.67e-11
        let earthMass = 5.98e24
        let earthRadius = 6367444.7
        let baseG = G * earthMass / (earthRadius * earthRadius)
        let planetG = G * planetMass * earthMass / (planetRadius * planetRadius * 1e6)
        let planetDensity = planetMass * earthMass / (4.0 / 3.0 * M_PI * planetRadius * planetRadius * planetRadius) * 1e-9 // in SI units of kg/m^3
        let planetM2Str = String(format: "%#.3g", planetG)
        let planetGStr = String(format: "%#.3g", planetG / baseG)
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
            densityString += "\n**Likely**: " + likelyTypes.sorted().joined(separator: ", ")
        }
        if maybeTypes.count > 0 {
            densityString += "\n**Possible**: " + maybeTypes.sorted().joined(separator: ", ")
        }
        let planetDensityStr = String(format: "%#.3g", planetDensity)

        message.replyToChannel("The gravity for a planet with \(planetMass) Earth Masses and a radius of \(planetRadius) km is **\(planetM2Str)** m/s^2 or **\(planetGStr)** g. It has a density of **\(planetDensityStr)** kg/m^3.\(densityString)")
    }

    fileprivate func handleRoute(_ args: [String], message: Message) {
        var maxDistance = 1000.0
        if args.count < 2 {
            message.replyToChannel("Missing arguments. Expected: <JumpRange> <SgrA* distance in kly> [optional max plot in ly]")
            return
        }

        guard let jumpRange = Double(args[0]), var distance = Double(args[1]) else {
            message.replyToChannel("Jump range and distance parameters should be numbers. Expected: <JumpRange> <SgrA* distance in kly> [optional max plot in ly]")
            return
        }

        if args.count > 2 {
            if let optMaxDistance = Double(args[2]) {
                maxDistance = min(optMaxDistance, maxDistance) // Only reduce it since 1000 ly is maximum routable
            }
        }

        if distance >= 100 {
            distance /= 1000.0 // Assume accidental entry in ly instead of kly.
        }
        let calc = {()->Double in
            let N = floor(maxDistance / jumpRange)
            let M = N * jumpRange
            return M - ((N / 4) + (distance * 2))
        }
        var estRange = calc()
        if estRange <= 0 {
            message.replyToChannel("Error: Calculation resulted in a negative distance. Please check your input.");
            return
        }
        if maxDistance < 1000.0 {
            let maxRange = maxDistance
            repeat {
                maxDistance += jumpRange
                let improvement = calc()
                if improvement > maxRange {
                    break // too far
                }
                estRange = improvement
            } while true;
        }
        let marginOfError = estRange * 0.0055
        message.replyToChannel(String(format: "Estimated plot range should be around **%.0f ly** - check range *%.0f to %.0f ly*", estRange, floor(estRange - marginOfError), ceil(estRange + marginOfError)))
    }
}

private extension Double {
    var toRadians: Double {
        return self * M_PI / 180.0
    }
    var toDegrees: Double {
        return self * 180.0 / M_PI
    }
    func toString(_ fractionDigits:Int, minFractionDigits: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = minFractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}


class PlanetaryMath {
    typealias LatLong = (lat:Double, lon:Double)

    class func calculateBearingAndDistance(start: LatLong, end: LatLong, radius: Double?) -> (bearing:Double, distance:Double?) {
        let λ1 = start.lon.toRadians
        let λ2 = end.lon.toRadians
        let φ1 = start.lat.toRadians
        let φ2 = end.lat.toRadians
        let y = sin(λ2 - λ1) * cos(φ2)
        let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(λ2 - λ1)
        let bearing = (atan2(y, x).toDegrees + 360).truncatingRemainder(dividingBy: 360)

        var distance: Double?
        if let R = radius {
            if R > 0 {
                let Δφ = (end.lat - start.lat).toRadians
                let Δλ = (end.lon - start.lon).toRadians

                let a = sin(Δφ / 2) * sin(Δφ / 2) + cos(φ1) * cos(φ2) * sin(Δλ / 2) * sin(Δλ / 2);
                let c = 2 * atan2(sqrt(a), sqrt(1 - a));

                distance = R * c
            }
        }
        return (bearing, distance)
    }

    class func distanceFor(_ km: Double?) -> String {
        var distance = ""
        if let km = km {
            if km > 1 {
                distance = String(format: " for %.2f km", km)
            } else {
                distance = String(format: " for %.1f m", km * 1000.0)
            }
        }
        return distance
    }
}

extension String {
    init(latlong: PlanetaryMath.LatLong) {
        self.init("(\(latlong.lat.toString(4)), \(latlong.lon.toString(4)))")!
    }
}
