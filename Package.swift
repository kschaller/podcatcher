// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Podcatcher",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "podcatcher", targets: ["Podcatcher"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "Podcatcher",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "PodcatcherTests",
            dependencies: ["Podcatcher"]
        )
    ]
)
