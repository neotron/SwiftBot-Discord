import PackageDescription

let package = Package(
    name: "SwiftBot",
    targets: [
        Target(
            name: "SwiftBot",
            dependencies: [
                ]),
        
        ],
    dependencies: [
        .Package(url: "https://github.com/lyft/mapper", majorVersion: 6),
        .Package(url: "https://github.com/PerfectlySoft/Perfect-CURL.git", majorVersion: 2),
        .Package(url: "https://github.com/nuclearace/SwiftDiscord", majorVersion: 0),
        .Package(url: "https://github.com/behrang/YamlSwift", majorVersion: 3),
        ]
)
