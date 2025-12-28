// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Serverable",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "APIModels", targets: ["APIModels"]),
        .library(name: "CoreNetworking", targets: ["CoreNetworking"]),
        .library(name: "Serverable", targets: ["Serverable"])
    ],
    targets: [
        .target(
            name: "APIModels",
            path: "Sources/APIModels"
        ),
        .target(
            name: "CoreNetworking",
            dependencies: ["APIModels"],
            path: "Sources/CoreNetworking"
        ),
        .target(
            name: "Serverable",
            dependencies: ["APIModels", "CoreNetworking"],
            path: "Sources/Serverable"
        ),
        .testTarget(
            name: "ServerableTests",
            dependencies: ["Serverable"]
        )
    ]
)
