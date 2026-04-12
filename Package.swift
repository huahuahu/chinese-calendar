// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ChineseCalendar",
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
            name: "ChineseCalendarCore"
        ),
        .target(
            name: "ChineseCalendarData",
            dependencies: ["ChineseCalendarCore"]
        ),
        .target(
            name: "ChineseCalendarPersistence",
            dependencies: ["ChineseCalendarCore", "ChineseCalendarData"]
        ),
        .target(
            name: "ChineseCalendarUI",
            dependencies: ["ChineseCalendarCore", "ChineseCalendarData"]
        ),
        .testTarget(
            name: "ChineseCalendarCoreTests",
            dependencies: ["ChineseCalendarCore"]
        ),
        .testTarget(
            name: "ChineseCalendarDataTests",
            dependencies: ["ChineseCalendarData"]
        )
    ]
)
