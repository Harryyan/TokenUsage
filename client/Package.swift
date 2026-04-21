// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TokenUsage",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "TokenUsage",
            path: "TokenUsage",
            exclude: ["Info.plist"]
        )
    ]
)
