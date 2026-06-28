// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JobDog",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "JobDog",
            path: "Sources"
        )
    ]
)
