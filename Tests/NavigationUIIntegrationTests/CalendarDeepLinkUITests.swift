import XCTest

/// 系统确认按钮由独立 UI 测试进程真实点击；App 单测负责核对等待确认时的导航状态。
nonisolated class CalendarDeepLinkUITests: XCTestCase {
    @MainActor func testCancellingEmperorDeepLinkPreservesTheSheetAndSourceTabThenApprovalNavigates() throws {
        let app = launchApplication()
        defer { app.terminate() }
        try openNavigationSheet(in: app)
        let cancelledPageID = try navigationPageID(in: app)

        let firstConfirmation = try openDeepLink(
            "chinesecalendar://emperor/ming_emperor_0000", in: app,
            message: "将关闭当前弹出页面及其子页面，前往链接中的皇帝详情。"
        )
        firstConfirmation.buttons["留在当前页面"].tap()
        XCTAssertTrue(firstConfirmation.waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[cancelledPageID].wait(for: \.isHittable, toEqual: true, timeout: 10))
        XCTAssertEqual(try navigationPageID(in: app), cancelledPageID)
        assertModalRoot(in: app)

        // 通过正常关闭返回来源，验证取消没有提前切换根 Tab；随后重新打开模态验证批准分支。
        app.navigationBars["导航测试"].buttons["关闭"].tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.tabBars.buttons["设置"].isSelected)
        XCTAssertFalse(app.navigationBars["朱元璋(太祖)"].exists)
        try openNavigationSheet(in: app)
        let approvedPageID = try navigationPageID(in: app)
        XCTAssertNotEqual(approvedPageID, cancelledPageID)

        let secondConfirmation = try openDeepLink(
            "chinesecalendar://emperor/ming_emperor_0000", in: app,
            message: "将关闭当前弹出页面及其子页面，前往链接中的皇帝详情。"
        )
        secondConfirmation.buttons["关闭并前往"].tap()
        XCTAssertTrue(secondConfirmation.waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["朱元璋(太祖)"].wait(for: \.isHittable, toEqual: true, timeout: 10))
        XCTAssertTrue(app.tabBars.buttons["朝代"].isSelected)
        XCTAssertFalse(app.navigationBars["导航测试"].exists)
        XCTAssertFalse(app.staticTexts[approvedPageID].exists)
    }

    @MainActor func testApprovingYearDeepLinkDismissesTheWholeModalTreeBeforeShowingCalendar() throws {
        let app = launchApplication()
        defer { app.terminate() }
        try openNavigationSheet(in: app)
        let parentPageID = try navigationPageID(in: app)
        try tapButton("全屏打开测试页", in: app)
        let childPageID = try navigationPageID(in: app)
        XCTAssertNotEqual(childPageID, parentPageID)
        assertModalRoot(in: app)

        let confirmation = try openDeepLink(
            "chinesecalendar://year/2026", in: app,
            message: "将关闭当前弹出页面及其子页面，前往公元 2026 年。"
        )
        confirmation.buttons["关闭并前往"].tap()
        XCTAssertTrue(confirmation.waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["日历"].wait(for: \.isHittable, toEqual: true, timeout: 10))
        XCTAssertTrue(app.tabBars.buttons["日历"].isSelected)
        XCTAssertFalse(app.navigationBars["导航测试"].exists)
        XCTAssertFalse(app.staticTexts[parentPageID].exists)
        XCTAssertFalse(app.staticTexts[childPageID].exists)
    }

    @MainActor private func launchApplication() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN",
            "--deep-link", "chinesecalendar://year/2024"
        ]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["设置"].waitForExistence(timeout: 30))
        return app
    }

    @MainActor private func openNavigationSheet(in app: XCUIApplication) throws {
        let settingsTab = app.tabBars.buttons["设置"]
        XCTAssertTrue(settingsTab.wait(for: \.isHittable, toEqual: true, timeout: 10))
        settingsTab.tap()
        XCTAssertTrue(settingsTab.isSelected)
        let debugButtons = app.buttons.matching(identifier: "调试操作")
        for _ in 0 ..< 4 {
            if debugButtons.allElementsBoundByIndex.contains(where: \.isHittable) { break }
            app.swipeUp()
        }
        let debugLabel = app.staticTexts["调试操作"].firstMatch
        XCTAssertTrue(debugLabel.waitForExistence(timeout: 10))
        // Form 的整行 AX 按钮可点击，但行中央不在实际菜单控件内；按标签的实时位置触摸。
        debugLabel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        try tapButton("导航测试", in: app)
        try tapButton("Sheet 打开测试页", in: app)
        XCTAssertTrue(app.navigationBars["导航测试"].waitForExistence(timeout: 10))
        assertModalRoot(in: app)
    }

    @MainActor private func tapButton(_ label: String, in app: XCUIApplication) throws {
        let matches = app.buttons.matching(identifier: label)
        XCTAssertTrue(matches.firstMatch.waitForExistence(timeout: 10), "找不到按钮：\(label)")
        let button = try XCTUnwrap(matches.allElementsBoundByIndex.filter(\.isHittable).min {
            $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height
        }, "按钮不可点击：\(label)")
        button.tap()
    }

    @MainActor private func navigationPageID(in app: XCUIApplication) throws -> String {
        let uuidPattern = "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}"
        let pages = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", uuidPattern))
        XCTAssertTrue(pages.firstMatch.waitForExistence(timeout: 10))
        let page = try XCTUnwrap(pages.allElementsBoundByIndex.first(where: \.isHittable))
        return page.label
    }

    @MainActor private func assertModalRoot(in app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["模态作用域"].waitForExistence(timeout: 10))
        let pathDepth = app.cells.containing(.staticText, identifier: "当前层 Push 页数").firstMatch
        XCTAssertTrue(pathDepth.staticTexts["0"].exists)
    }

    @MainActor private func openDeepLink(
        _ address: String,
        in app: XCUIApplication,
        message: String
    ) throws -> XCUIElement {
        let url = try XCTUnwrap(URL(string: address))
        // 系统投递 URL 给现有进程；XCUIApplication.open 会按 launch 语义重启 App。
        XCUIDevice.shared.system.open(url)
        let confirmation = app.alerts["离开当前页面？"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 10))
        XCTAssertTrue(confirmation.staticTexts[message].exists)
        XCTAssertTrue(confirmation.buttons["留在当前页面"].isHittable)
        XCTAssertTrue(confirmation.buttons["关闭并前往"].isHittable)
        return confirmation
    }
}
