// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChatAutomationApp",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "ChatAutomationApp",
            path: "Sources/ChatAutomationApp"
        )
    ]
)
