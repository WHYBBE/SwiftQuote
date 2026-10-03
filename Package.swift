// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftQuote",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "SwiftQuote",
            path: "Sources/SwiftQuote",
            resources: [.process("Resources")]
        )
    ]
)
