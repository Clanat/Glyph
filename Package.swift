// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Glyph",
    dependencies: [
        .package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git", from: "1.0.0"),
        .package(url: "https://github.com/Bouke/SRP.git", from: "3.0.0"),
        .package(url: "../CLibEvent", .branch("master"))
    ],
    targets: [
        .target(
            name: "GlyphCore",
            dependencies: [
                
            ]
        ),
        .target(
            name: "GlyphMasterServer",
            dependencies: [
                
            ]
        ),
        .target(
            name: "GlyphRealmServer",
            dependencies: [
                "GlyphNetworkFramework",
                "SwiftyBeaver",
                "SRP"
            ]
        ),
        .target(
            name: "GlyphNetworkFramework",
            dependencies: [
                "GlyphCore"
            ]
        ),
    ]
)
