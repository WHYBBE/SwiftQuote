// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftQuote",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "SwiftQuote",
            path: "Sources/SwiftQuote",
            resources: [.process("Resources")]
        )
    ]
)
