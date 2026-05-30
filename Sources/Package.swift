// swift-tools-version: 6.2
import PackageDescription

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
    targets: [
        .target(
            name: "ChineseCalendarLogging",
            path: "ChineseCalendarLogging",
            exclude: ["README.md", "Tests"]
        ),
        .target(
            name: "ChineseCalendarCore",
            dependencies: ["ChineseCalendarLogging"],
            path: "ChineseCalendarCore",
            exclude: ["Tests"]
        ),
        .target(
            name: "ChineseCalendarData",
            dependencies: [
                "ChineseCalendarCore",
                "ChineseCalendarLogging"
            ],
            path: "ChineseCalendarData",
            exclude: ["Tests"]
        ),
        .target(
            name: "ChineseCalendarPersistence",
            dependencies: [
                "ChineseCalendarCore",
                "ChineseCalendarData",
                "ChineseCalendarLogging"
            ],
            path: "ChineseCalendarPersistence"
        ),
        .target(
            name: "ChineseCalendarUI",
            dependencies: [
                "ChineseCalendarCore",
                "ChineseCalendarData",
                "ChineseCalendarPersistence",
                "ChineseCalendarLogging"
            ],
            path: "ChineseCalendarUI",
            exclude: ["Tests"]
        ),
        .testTarget(
            name: "ChineseCalendarCoreTests",
            dependencies: ["ChineseCalendarCore"],
            path: "ChineseCalendarCore/Tests"
        ),
        .testTarget(
            name: "ChineseCalendarDataTests",
            dependencies: ["ChineseCalendarCore", "ChineseCalendarData"],
            path: "ChineseCalendarData/Tests"
        ),
        .testTarget(
            name: "ChineseCalendarLoggingTests",
            dependencies: ["ChineseCalendarLogging"],
            path: "ChineseCalendarLogging/Tests"
        ),
        .testTarget(
            name: "ChineseCalendarUITests",
            dependencies: ["ChineseCalendarUI"],
            path: "ChineseCalendarUI/Tests"
        )
    ]
)
