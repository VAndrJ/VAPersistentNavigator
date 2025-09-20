// swift-tools-version: 6.2

import PackageDescription

let settings: [SwiftSetting] = [
    .defaultIsolation(MainActor.self),
    .strictMemorySafety(),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "VAPersistentNavigator",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .macCatalyst(.v13),
    ],
    products: [
        .library(
            name: "VAPersistentNavigator",
            targets: ["VAPersistentNavigator"]
        )
    ],
    targets: [
        .target(
            name: "VAPersistentNavigator",
            swiftSettings: settings
        ),
        .testTarget(
            name: "VAPersistentNavigatorTests",
            dependencies: ["VAPersistentNavigator"],
            swiftSettings: settings
        ),
    ]
)
