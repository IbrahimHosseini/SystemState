// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SystemState",
    targets: [
        
        .executableTarget(
            name: "SystemState",
            dependencies: ["CPU", "RAM"],
            path: "Sources/main"
        ),
        
        // MARK: - CPU
        .target(
            name: "CPU",
            dependencies: ["Kit"],
            path: "Sources/CPU"
        ),
        
        // MARK: - RAM
        .target(
            name: "RAM",
            dependencies: ["Kit"],
            path: "Sources/RAM"
        ),
        
        // MARK: - Kit
        .target(
            name: "Kit",
            dependencies: ["LLDB", "SMC"],
            path: "Sources/Kit"
        ),
        
        // MARK: - SMC
        .target(
            name: "SMC",
            path: "Sources/SMC"
        ),
        
        // MARK: - LLDB
        .target(
            name: "LLDB",
            path: "Sources/LLDB",
            publicHeadersPath: "include"
        ),
    ]
)
