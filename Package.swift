// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "courierpro",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "courierpro", targets: ["courierpro"])
    ],
    targets: [
        .executableTarget(
            name: "courierpro",
            path: "courierpro",
            exclude: [
                "Assets.xcassets",
                "Resources/Assets.xcassets"
            ]
        ),
        .testTarget(
            name: "courierproTests",
            dependencies: ["courierpro"],
            path: "courierproTests"
        )
    ]
)
