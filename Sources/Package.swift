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
            name: "ChineseCalendarUI",
            targets: ["ChineseCalendarUI"]
        )
    ],
    targets: [
        .target(
            name: "ChineseCalendarCore",
            path: "ChineseCalendarCore",
            exclude: ["Tests"]
        ),
        .target(
            name: "ChineseCalendarData",
            dependencies: ["ChineseCalendarCore"],
            path: "ChineseCalendarData",
            exclude: ["Tests"]
        ),
        .target(
            name: "ChineseCalendarPersistence",
            dependencies: ["ChineseCalendarCore", "ChineseCalendarData"],
            path: "ChineseCalendarPersistence"
        ),
        .target(
            name: "ChineseCalendarUI",
            dependencies: ["ChineseCalendarCore", "ChineseCalendarData"],
            path: "ChineseCalendarUI"
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
        )
    ]
)
