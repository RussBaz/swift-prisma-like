// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "swift-prisma-like",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "swift-prisma-runtime",
            targets: ["Runtime"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.31.1"),
        .package(url: "https://github.com/vapor/sqlite-kit.git", from: "4.5.2"),
    ],
    targets: [
        .target(name: "Core", swiftSettings: swiftSettings),
        .executableTarget(
            name: "Example",
            dependencies: [
                .product(name: "SQLKit", package: "sql-kit"),
                .product(name: "SQLiteKit", package: "sqlite-kit"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(name: "Plugin", swiftSettings: swiftSettings),
        .target(name: "Runtime", swiftSettings: swiftSettings),
        .executableTarget(
            name: "Tool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SwiftPrismaLikeTests",
            dependencies: ["Core"],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("ImportObjcForwardDeclarations"),
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("DeprecateApplicationMain"),
    .enableUpcomingFeature("GlobalConcurrency"),
    .enableUpcomingFeature("IsolatedDefaultValues"),
    .enableExperimentalFeature("StrictConcurrency"),
] }
