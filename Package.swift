// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ChineseCalendar",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
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
