// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Podcatcher",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "podcatcher", targets: ["Podcatcher"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "Podcatcher",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/Podcatcher"
        ),
        .testTarget(
            name: "PodcatcherTests",
            dependencies: ["Podcatcher"],
            path: "Tests/PodcatcherTests"
        )
    ]
)