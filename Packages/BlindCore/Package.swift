// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BlindCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "BlindCore",
            targets: ["BlindCore"]
        ),
    ],
    targets: [
        .target(
            name: "BlindCore",
            dependencies: []
        ),
        .testTarget(
            name: "BlindCoreTests",
            dependencies: ["BlindCore"]
        ),
    ]
)
