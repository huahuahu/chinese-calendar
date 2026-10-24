import SnapshotTesting
import XCTest

// 显式录制当前 UI；日常测试严格比较，不因缺少基准而自动生成图片。
// swiftformat:disable:next modifierOrder
nonisolated final class CalendarSnapshotTests: XCTestCase {
    @MainActor
    func testPhonePages() async throws {
        for scene in SnapshotScene.allCases {
            try await check(scene, appearance: .phone)
        }
    }

    @MainActor
    func testTabletPages() async throws {
        for scene in [SnapshotScene.calendar, .history, .selectedHistory, .dynasty] {
            try await check(scene, appearance: .tablet)
        }
    }

    @MainActor
    func testDarkPages() async throws {
        for scene in [SnapshotScene.calendar, .emperor] {
            try await check(scene, appearance: .dark)
        }
    }

    @MainActor
    func testAccessibilityCalendar() async throws {
        try await check(.calendar, appearance: .accessibility)
    }

    @MainActor
    private func check(
        _ scene: SnapshotScene, appearance: SnapshotAppearance,
        file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        try requireBaselineEnvironment()
        let image = try await SnapshotRenderer.capture(SnapshotSampleHost(scene: scene), appearance: appearance)
        XCTAssertEqual(image.size, appearance.size, "截图必须完整覆盖固定视口", file: file, line: line)
        assertSnapshot(
            of: image,
            // 系统玻璃边缘跨进程有 1/255 的色阶波动；每个像素仍须通过感知比较。
            as: .image(precision: 1, perceptualPrecision: 0.99, scale: 1),
            named: appearance.rawValue,
            record: ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1" ? .all : .never,
            file: file,
            testName: scene.slug,
            line: line
        )
    }

    private func requireBaselineEnvironment() throws {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        #if targetEnvironment(simulator) && arch(arm64)
            if version.majorVersion == 27, version.minorVersion == 0, version.patchVersion == 0 { return }
        #endif
        throw NSError(domain: "CalendarSnapshotEnvironment", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "截图基准要求 arm64 iOS 27.0 Simulator，当前为 \(version)。"
        ])
    }
}
