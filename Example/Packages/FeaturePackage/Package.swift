// swift-tools-version: 6.2

import PackageDescription

let settings: [SwiftSetting] = [
    .defaultIsolation(MainActor.self),
    .strictMemorySafety(),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "FeaturePackage",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .macCatalyst(.v13),
    ],
    products: [
        .library(
            name: "FeaturePackage",
            targets: ["FeaturePackage"]
        )
    ],
    dependencies: [
        .package(path: "../../../../VAPersistentNavigator")
    ],
    targets: [
        .target(
            name: "FeaturePackage",
            dependencies: ["VAPersistentNavigator"],
            swiftSettings: settings
        )
    ]
)
