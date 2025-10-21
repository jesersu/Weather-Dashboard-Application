// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkingKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "NetworkingKit",
            targets: ["NetworkingKit"]),
    ],
    targets: [
        .target(
            name: "NetworkingKit"),
        .testTarget(
            name: "NetworkingKitTests",
            dependencies: ["NetworkingKit"]
        ),
    ]
)
