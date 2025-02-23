// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SystemState",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "systemstate",
            targets: ["systemstate"]
        ),
    ],
    targets: [
        
        // MARK: - System State
        .target(
            name: "systemstate",
            dependencies: [
                "CPU",
                "Memory",
                "Storage",
                "Battery",
                "DeviceInfo",
                "Sensors",
                "NetworkInfo",
            ],
            path: "Sources/systemstate"
        ),
        .testTarget(
            name: "systemstateTests",
            dependencies: ["systemstate"]),
        
        // MARK: - CPU
        .target(
            name: "CPU",
            dependencies: ["SystemKit", "Module"],
            path: "Sources/CPU"
        ),
        
        // MARK: - Memory
        .target(
            name: "Memory",
            dependencies: ["SystemKit", "Module"],
            path: "Sources/Memory"
        ),
        
        // MARK: - Storage
        .target(
            name: "Storage",
            dependencies: ["SystemKit", "Module"],
            path: "Sources/Storage"
        ),
        
        // MARK: - Battery
        .target(
            name: "Battery",
            dependencies: ["SystemKit", "Module"],
            path: "Sources/Battery"
        ),
        
        // MARK: - Network
        .target(
            name: "NetworkInfo",
            dependencies: ["SystemKit", "Module"],
            path: "Sources/Network"
        ),
        
        // MARK: - Device Info
        .target(
            name: "DeviceInfo",
            dependencies: ["SystemKit"],
            path: "Sources/DeviceInfo"
        ),
        
        // MARK: - Sensores
        .target(
            name: "Sensors",
            dependencies: [
                "SystemKit",
                "SMC",
                "Common",
                "Module",
                "Bridge",
            ],
            path: "Sources/Sensors"
        ),
        
        // MARK: - Dependencies
        
        // MARK: Module
        .target(
            name: "Bridge",
            path: "Sources/Bridge",
            publicHeadersPath: "include"
        ),
        
        // MARK: Module
        .target(
            name: "Module",
            dependencies: ["SystemKit"],
            path: "Sources/Module"
        ),
        
        // MARK: Extensions
        .target(
            name: "Extensions",
            dependencies: ["Common"],
            path: "Sources/Extensions"
        ),
        
        // MARK: Common
        .target(
            name: "Common",
            path: "Sources/Common"
        ),
        
        // MARK: Constants
        .target(
            name: "Constants",
            dependencies: ["Common"],
            path: "Sources/Constants"
        ),
        
        // MARK: SystemKit
        .target(
            name: "SystemKit",
            dependencies: [
                "SMC",
                "Constants",
                "Common"
            ],
            path: "Sources/SystemKit"
        ),
        
        // MARK: SMC
        .target(
            name: "SMC",
            dependencies: ["Extensions"],
            path: "Sources/SMC"
        ),
    ]
)
