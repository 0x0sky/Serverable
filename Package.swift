// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Serverable",
    platforms: [
        .iOS(.v26),
        .macOS(.v11),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "APIModels", targets: ["APIModels"]),
        .library(name: "Serverable", targets: ["Serverable"])
    ],
    targets: [
        .target(
            name: "APIModels",
            path: "Sources/APIModels"
        ),
        .target(
            name: "Serverable",
            dependencies: ["APIModels"],
            path: "Sources/Serverable"
        )
    ]
)