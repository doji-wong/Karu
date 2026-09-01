// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Karu",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "KaruCore",
            targets: ["KaruCore"]
        ),
        .executable(
            name: "Karu",
            targets: ["Karu"]
        ),
        .executable(
            name: "KaruWidgets",
            targets: ["KaruWidgets"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "KaruCore",
            dependencies: []
        ),
        .executableTarget(
            name: "Karu",
            dependencies: ["KaruCore"]
        ),
        .executableTarget(
            name: "KaruWidgets",
            dependencies: ["KaruCore"]
        ),
        .testTarget(
            name: "KaruCoreTests",
            dependencies: ["KaruCore"]
        )
    ]
)
