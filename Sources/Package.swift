// swift-tools-version: 6.3
import PackageDescription

let nonisolatedSwiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .defaultIsolation(nil)
]

let mainActorSwiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .defaultIsolation(MainActor.self)
]

let package = Package(
    name: "ChineseCalendarSources",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "ChineseCalendarCore",
            targets: ["ChineseCalendarCore"]
        ),
        .library(
            name: "ChineseCalendarData",
            targets: ["ChineseCalendarData"]
        ),
        .library(
            name: "ChineseCalendarPersistence",
            targets: ["ChineseCalendarPersistence"]
        ),
        .library(
            name: "ChineseCalendarLogging",
            targets: ["ChineseCalendarLogging"]
        ),
        .library(
            name: "ChineseCalendarUI",
            targets: ["ChineseCalendarUI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git", .upToNextMajor(from: "7.0.0"))
    ],
    targets: [
        .target(
            name: "ChineseCalendarLogging",
            path: "ChineseCalendarLogging",
            exclude: ["README.md", "Tests"],
            swiftSettings: nonisolatedSwiftSettings
        ),
        .target(
            name: "ChineseCalendarCore",
            dependencies: ["ChineseCalendarLogging"],
            path: "ChineseCalendarCore",
            exclude: ["Tests"],
            swiftSettings: nonisolatedSwiftSettings
        ),
        .target(
            name: "ChineseCalendarData",
            dependencies: [
                "ChineseCalendarCore",
                "ChineseCalendarLogging"
            ],
            path: "ChineseCalendarData",
            exclude: ["Tests"],
            swiftSettings: nonisolatedSwiftSettings
        ),
        .target(
            name: "ChineseCalendarPersistence",
            dependencies: [
                "ChineseCalendarCore",
                "ChineseCalendarData",
                "ChineseCalendarLogging"
            ],
            path: "ChineseCalendarPersistence",
            swiftSettings: nonisolatedSwiftSettings
        ),
        .target(
            name: "ChineseCalendarUI",
            dependencies: [
                "ChineseCalendarCore",
                "ChineseCalendarData",
                "ChineseCalendarPersistence",
                "ChineseCalendarLogging",
                .product(name: "SFSafeSymbols", package: "SFSafeSymbols")
            ],
            path: "ChineseCalendarUI",
            exclude: ["Tests"],
            swiftSettings: mainActorSwiftSettings
        ),
        .testTarget(
            name: "ChineseCalendarCoreTests",
            dependencies: ["ChineseCalendarCore"],
            path: "ChineseCalendarCore/Tests",
            swiftSettings: nonisolatedSwiftSettings
        ),
        .testTarget(
            name: "ChineseCalendarDataTests",
            dependencies: ["ChineseCalendarCore", "ChineseCalendarData"],
            path: "ChineseCalendarData/Tests",
            swiftSettings: nonisolatedSwiftSettings
        ),
        .testTarget(
            name: "ChineseCalendarLoggingTests",
            dependencies: ["ChineseCalendarLogging"],
            path: "ChineseCalendarLogging/Tests",
            swiftSettings: nonisolatedSwiftSettings
        ),
        .testTarget(
            name: "ChineseCalendarUITests",
            dependencies: ["ChineseCalendarUI"],
            path: "ChineseCalendarUI/Tests",
            swiftSettings: mainActorSwiftSettings
        )
    ]
)
