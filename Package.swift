// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IMap",
    platforms: [
        .iOS(.init("16.6"))
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "MapPack", targets: ["MapPack"]),
        .library(name: "NavigationTrackingCore", targets: ["NavigationTrackingCore"])
    ],
    dependencies: [
        // ✅ Google Maps SDK via SPM
        .package(url: "https://github.com/googlemaps/ios-maps-sdk", from: "10.15.0"),
        .package(url: "https://github.com/maplibre/maplibre-navigation-ios", exact: "4.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NavigationTrackingCore"
        ),
        .target(
            name: "MapPack",
            dependencies: [
                "NavigationTrackingCore",
                .product(name: "GoogleMaps", package: "ios-maps-sdk"),
                .product(name: "MapboxNavigation", package: "maplibre-navigation-ios"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "IMapTests",
            dependencies: ["MapPack"]
        ),
    ],
    swiftLanguageModes: [.version("6"), .v5]
)
