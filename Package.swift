import PackageDescription

let package = Package(
    name: "SwiftBot",
    targets: [
        Target(
            name: "SwiftBot",
            dependencies: [
                .Target(name: "EVReflection"),
                .Target(name: "AlamofireJsonToObjects")
                ]),
        
        ],
    dependencies: [
        .Package(url: "https://github.com/nuclearace/SwiftDiscord", majorVersion: 0, minor: 5),
        .Package(url: "https://github.com/Alamofire/Alamofire.git", majorVersion: 4, minor: 2),
        .Package(url: "https://github.com/behrang/YamlSwift", majorVersion: 3, minor: 3),
        //.Package(url: "git@github.com:evermeer/AlamofireJsonToObjects.git", majorVersion: 2, minor: 4),
        ]
)
