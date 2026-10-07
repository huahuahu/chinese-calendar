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
    defaultLocalization: "zh-Hans",
    platforms: [
        .iOS(.v26),
        // Deployment floor for macOS host tools selecting Core/Persistence; UI remains iOS-only.
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "ChineseCalendarLocalization",
            targets: ["ChineseCalendarLocalization"]
        ),
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
            name: "NavigationCore",
            targets: ["NavigationCore"]
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
            name: "ChineseCalendarLocalization",
            path: "ChineseCalendarLocalization",
            exclude: ["README.md", "Tests"],
            resources: [.process("Resources/Calendar.xcstrings")],
            swiftSettings: nonisolatedSwiftSettings
        ),
        .target(
            name: "ChineseCalendarLogging",
            path: "ChineseCalendarLogging",
            exclude: ["README.md", "Tests"],
            swiftSettings: nonisolatedSwiftSettings
        ),
        .target(
            name: "ChineseCalendarCore",
            dependencies: ["ChineseCalendarLogging", "ChineseCalendarLocalization"],
            path: "ChineseCalendarCore",
            exclude: ["Tests"],
            swiftSettings: nonisolatedSwiftSettings
        ),
        .target(
            name: "NavigationCore",
            dependencies: ["ChineseCalendarLogging"],
            path: "NavigationCore",
            exclude: ["README.md"],
            swiftSettings: mainActorSwiftSettings
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
            exclude: ["Tests"],
            swiftSettings: nonisolatedSwiftSettings
        ),
        .target(
            name: "ChineseCalendarUI",
            dependencies: [
                "ChineseCalendarLocalization",
                "ChineseCalendarCore",
                "ChineseCalendarData",
                "ChineseCalendarPersistence",
                "ChineseCalendarLogging",
                "NavigationCore",
                .product(name: "SFSafeSymbols", package: "SFSafeSymbols")
            ],
            path: "ChineseCalendarUI",
            exclude: ["Tests"],
            swiftSettings: mainActorSwiftSettings
        ),
        .testTarget(
            name: "ChineseCalendarLocalizationTests",
            dependencies: ["ChineseCalendarLocalization"],
            path: "ChineseCalendarLocalization/Tests",
            swiftSettings: nonisolatedSwiftSettings
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
            name: "ChineseCalendarPersistenceTests",
            dependencies: ["ChineseCalendarPersistence"],
            path: "ChineseCalendarPersistence/Tests",
            swiftSettings: nonisolatedSwiftSettings
        ),
        .testTarget(
            name: "NavigationCoreTests",
            dependencies: ["NavigationCore"],
            path: "NavigationCoreTests",
            swiftSettings: mainActorSwiftSettings
        ),
        .testTarget(
            name: "ChineseCalendarUITests",
            dependencies: ["ChineseCalendarUI", "ChineseCalendarLocalization"],
            path: "ChineseCalendarUI/Tests",
            swiftSettings: mainActorSwiftSettings
        )
    ]
)
