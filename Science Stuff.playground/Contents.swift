//: Playground - noun: a place where people can play

import Cocoa

var str = "Hello, playground"
extension Double{
    var toRadians: Double {
        return self * M_PI / 180.0
    }
    var toDegrees: Double {
        return self * 180.0 / M_PI
    }
}
typealias LatLong = (lat: Double, lon: Double)


private func calculateBearing(start: LatLong, end: LatLong, radius: Double?) -> (bearing: Double, distance: Double) {
    let λ1 = start.lat.toRadians
    let λ2 = end.lat.toRadians
    let φ1 = start.lon.toRadians
    let φ2 = end.lon.toRadians
    let y = sin(λ2-λ1) * cos(φ2)
    let x = cos(φ1)*sin(φ2) - sin(φ1)*cos(φ2)*cos(λ2-λ1)
    let bearing = (atan2(y, x).toDegrees + 450)%360
    var distance = 0.0
    if let R = radius {
        let Δφ = (end.lat-start.lat).toRadians
        let Δλ = (end.lon-start.lon).toRadians
        
        let a = sin(Δφ/2) * sin(Δφ/2) + cos(φ1) * cos(φ2) * sin(Δλ/2) * sin(Δλ/2);
        let c = 2 * atan2(sqrt(a), sqrt(1-a));
        
        distance = R * c
    }
    
    return (bearing, distance)
}

let result = calculateBearing((-67.5169, -96.0039), end: (-66.88, -96.0), radius: 507.0)
print("Bearing = \(result.bearing), distance: \(result.distance*1000) m")



calculateBearing((10,10), end: (11,10), radius: 6500.0)
calculateBearing((10,10), end: (10,11), radius: 6500.0)
calculateBearing((10,10), end: (10,9), radius: 6500.0)
calculateBearing((10,10), end: (9,10), radius: 6500.0)


