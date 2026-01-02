// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MyLibrary",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MyLibrary",
            targets: ["MyLibrary"]),
    ],
    targets: [
        .target(
            name: "MyLibrary",
            path: "Sources/MyLibrary"
        ),
        .testTarget(
            name: "MyLibraryTests",
            dependencies: ["MyLibrary"]
        ),
    ]
)
