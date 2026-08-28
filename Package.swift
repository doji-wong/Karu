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
        .testTarget(
            name: "KaruCoreTests",
            dependencies: ["KaruCore"]
        )
    ]
)
