// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DollarGeneralPersist",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "DollarGeneralPersist",
            targets: ["DollarGeneralPersist"]),
    ],
    targets: [
        .target(
            name: "DollarGeneralPersist"),
        .testTarget(
            name: "DollarGeneralPersistTests",
            dependencies: ["DollarGeneralPersist"]
        ),
    ]
)
