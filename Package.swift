// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Openbase",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "Openbase",
            targets: ["Openbase"]
        ),
    ],
    targets: [
        .target(
            name: "Openbase",
            path: "Sources/Openbase"
        ),
        .testTarget(
            name: "OpenbaseTests",
            dependencies: ["Openbase"]
        ),
    ]
)
