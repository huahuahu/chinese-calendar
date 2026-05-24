// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BuildChineseCalendarSeedStore",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(
            name: "ChineseCalendarSeedStoreBuilder",
            targets: ["ChineseCalendarSeedStoreBuilder"]
        )
    ],
    dependencies: [
        .package(path: "../../Sources")
    ],
    targets: [
        .executableTarget(
            name: "ChineseCalendarSeedStoreBuilder",
            dependencies: [
                .product(name: "ChineseCalendarCore", package: "Sources"),
                .product(name: "ChineseCalendarPersistence", package: "Sources")
            ]
        )
    ]
)
