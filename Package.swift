// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NMContentViews",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_15), .iOS(.v14), .tvOS(.v13), .watchOS(.v7)
    ],
    products: [
        .library(
            name: "NMContentViews",
            targets: ["NMContentViews"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.41.0"),
    ],
    targets: [
        .target(
            name: "NMContentViews",
            dependencies: [
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"),
            ]),
        .testTarget(
            name: "NMContentViewsTests",
            dependencies: [
                "NMContentViews",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"),
            ]),
    ]
)
