// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TrendsKit",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TrendsKit", targets: ["TrendsKit"])
    ],
    targets: [
        .target(
            name: "TrendsKit",
            resources: [.process("Resources")],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
        .testTarget(
            name: "TrendsKitTests",
            dependencies: ["TrendsKit"],
            resources: [.copy("Fixtures")]
        )
    ]
)
