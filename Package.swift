// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenbaseShared",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "AllAuthSwift",
            targets: ["AllAuthSwift"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.2"),
    ],
    targets: [
        .target(
            name: "AllAuthSwift",
            dependencies: ["SwiftyJSON"]
        ),
        .testTarget(
            name: "AllAuthSwiftTests",
            dependencies: ["AllAuthSwift"]
        ),
    ]
)
