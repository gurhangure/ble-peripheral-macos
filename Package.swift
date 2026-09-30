// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ble-peripheral-macos",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ble-peripheral",
            targets: ["BLEPeripheral"]
        )
    ],
    targets: [
        .executableTarget(
            name: "BLEPeripheral"
        )
    ]
)
