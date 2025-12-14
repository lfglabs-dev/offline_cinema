// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OfflineCinema",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "OfflineCinema", targets: ["OfflineCinema"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "OfflineCinema",
            dependencies: [],
            path: "OfflineCinema",
            exclude: [
                "Info.plist",
                "OfflineCinema.entitlements"
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)

