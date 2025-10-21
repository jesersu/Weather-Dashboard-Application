// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DollarGeneralTemplateHelpers",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DollarGeneralTemplateHelpers",
            targets: ["DollarGeneralTemplateHelpers"]),
    ],
    targets: [
        .target(
            name: "DollarGeneralTemplateHelpers"),
        .testTarget(
            name: "DollarGeneralTemplateHelpersTests",
            dependencies: ["DollarGeneralTemplateHelpers"]
        ),
    ]
)
