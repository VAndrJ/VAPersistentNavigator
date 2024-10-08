// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VAPersistentNavigator",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v13)],
    products: [
        .library(
            name: "VAPersistentNavigator",
            targets: ["VAPersistentNavigator"]
        ),
    ],
    targets: [
        .target(
            name: "VAPersistentNavigator"
        ),
        .testTarget(
            name: "VAPersistentNavigatorTests",
            dependencies: ["VAPersistentNavigator"]
        ),
    ],
    swiftLanguageModes: [.version("6")]
)
