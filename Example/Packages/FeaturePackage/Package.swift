// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FeaturePackage",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v13)],
    products: [
        .library(
            name: "FeaturePackage",
            targets: ["FeaturePackage"]
        ),
    ],
    dependencies: [
        .package(path: "../../../../VAPersistentNavigator"),
    ],
    targets: [
        .target(
            name: "FeaturePackage",
            dependencies: ["VAPersistentNavigator"]
        ),
    ],
    swiftLanguageModes: [.version("6")]
)
