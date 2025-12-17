// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IMap",
    platforms: [
        .iOS(.init("16.6"))
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "MapPack", targets: ["MapPack"])
    ],
    dependencies: [
        // ✅ Google Maps SDK via SPM
        .package(url: "https://github.com/googlemaps/ios-maps-sdk", from: "10.4.0"),
        .package(url: "https://github.com/maplibre/maplibre-navigation-ios", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MapPack",
            dependencies: [
                .product(name: "GoogleMaps", package: "ios-maps-sdk"),
                .product(name: "MapboxNavigation", package: "maplibre-navigation-ios"),
            ],
            resources: [
            ]
        ),
    ]
)
