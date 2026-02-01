// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FinansApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FinansApp", targets: ["FinansApp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "FinansApp",
            dependencies: [],
            path: "Sources"
        )
    ]
)
