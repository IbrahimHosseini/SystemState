// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SystemState",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "systemstate", targets: ["systemstate"]),
    ],
    targets: [
        
        // MARK: - System State
        .target(
            name: "systemstate",
            dependencies: ["CPU", "Memory", "Storage", "Battery"],
            path: "Sources/systemstate"
        ),
        .testTarget(
            name: "systemstateTests",
            dependencies: ["systemstate"]),
        
        // MARK: - CPU
        .target(
            name: "CPU",
            dependencies: ["Kit"],
            path: "Sources/CPU"
        ),
        
        // MARK: - Memory
        .target(
            name: "Memory",
            dependencies: ["Kit"],
            path: "Sources/Memory"
        ),
        
        // MARK: - Kit
        .target(
            name: "Kit",
            dependencies: ["SMC"],
            path: "Sources/Kit"
        ),
        
        // MARK: - SMC
        .target(
            name: "SMC",
            path: "Sources/SMC"
        ),
        
        // MARK: - Storage
        .target(
            name: "Storage",
            dependencies: ["Kit"],
            path: "Sources/Storage"
        ),
        
        // MARK: - Battery
        .target(
            name: "Battery",
            dependencies: ["Kit"],
            path: "Sources/Battery"
        ),
    ]
)
