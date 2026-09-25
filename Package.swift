// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Hopla",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Hopla", path: "Sources/Hopla"),
        .testTarget(name: "HoplaTests", dependencies: ["Hopla"], path: "Tests/HoplaTests"),
    ]
)
