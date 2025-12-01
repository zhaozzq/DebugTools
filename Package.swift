// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DebugTools",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "DebugTools",
            targets: ["DebugTools"]
        ),
        .library(
            name: "MultiLogHandler",
            targets: ["MultiLogHandler"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Pulse.git", from: "5.1.4"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.2"),
    ],
    targets: [
        .target(
            name: "DebugTools",
            dependencies: [
                .product(name: "PulseUI", package: "Pulse"),
                .product(name: "PulseProxy", package: "Pulse")
            ],
            path: "Sources/DebugTools"
        ),
        .testTarget(
            name: "DebugToolsTests",
            dependencies: ["DebugTools"],
            path: "Tests"
        ),
        .target(
            name: "MultiLogHandler",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ],
            path: "Sources/MultiLogHandler"
        )
    ]
)
