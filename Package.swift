// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "GlassOverlay",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "GlassOverlay",
            targets: ["GlassOverlay"]
        ),
    ],
    dependencies: [
        // GlassOverlay uses SharedUI.Buttons for branded button styles.
        // Pin upToNextMajor so non-breaking SharedUI updates ship automatically.
        .package(
            url: "https://github.com/wichtelimwald/shared-ui.git",
            .upToNextMajor(from: "0.1.0")
        ),
    ],
    targets: [
        .target(
            name: "GlassOverlay",
            dependencies: [
                .product(name: "SharedUI", package: "shared-ui"),
            ],
            path: "Sources/GlassOverlay",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "GlassOverlayTests",
            dependencies: ["GlassOverlay"],
            path: "Tests/GlassOverlayTests"
        ),
    ]
)
