// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "FeaturePackage",
    products: [
        .library(
            name: "FeaturePackage",
            targets: ["FeaturePackage"]
        ),
    ],
    dependencies: [
        .package(path: "../../VAPersistentNavigator"),
    ],
    targets: [
        .target(
            name: "FeaturePackage",
            dependencies: [.product(name: "VAPersistentNavigator", package: "VAPersistentNavigator")]
        ),
        .testTarget(
            name: "FeaturePackageTests",
            dependencies: ["FeaturePackage"]
        ),
    ]
)
