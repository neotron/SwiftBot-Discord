import PackageDescription

let package = Package(
    name: "SwiftBot", 
    dependencies: [
        .Package(url: "https://github.com/nuclearace/SwiftDiscord", majorVersion: 0, minor: 5) 
    ]
)
