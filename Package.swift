// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CodexResetsExpire",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "CodexResetsExpire",
            targets: ["CodexResetsExpire"]
        )
    ],
    targets: [
        .executableTarget(
            name: "CodexResetsExpire"
        ),
        .testTarget(
            name: "CodexResetsExpireTests",
            dependencies: ["CodexResetsExpire"]
        )
    ]
)
