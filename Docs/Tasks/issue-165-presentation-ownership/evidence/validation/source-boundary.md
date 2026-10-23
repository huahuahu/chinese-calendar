# Issue 165：源码边界与定向链接证据

本记录保存源码核对和 **2026-10-24 00:19（UTC+8）RunSomeTests 定向测试构建**的链接证据，不代表最终全量测试、普通 Run/Build 或 XCUITest 交互通过。后续仅调整 UI 测试选择器；归档时重新计算的生产源码／配置快照与原核对一致。

## 代码状态与核对范围

- 核对时 HEAD：`224b13aa38390c9f8f677ac9ab29a0980853655c`，包含未提交改动。
- 原源码核对：2026-10-23 23:50（UTC+8）；210 个文件组合 SHA256：`bfce413b8bb180197331520a2ae59df9fd7a94e394b4f67cf75ad6da7b58acd3`。
- 文件集合：`Sources/NavigationCore/**/*.swift`、`Sources/ChineseCalendarUI/**/*.swift`（排除 Tests）、`Apps/iOSApp/Sources/**/*.swift`、`Scripts/NavigationCoreAPI/*`，以及 `project.yml`、`Sources/Package.swift`、`Scripts/fix_xcodegen_local_package_backlinks.py`、`Scripts/validate_navigation_public_api.py`。按相对路径排序，以每个路径、NUL、原文、NUL 依次更新 SHA256；不包含生成工程和 UI 测试选择器。

## 源码结论

- App 生产源码对旧集中会话字典、资源 projection、内部 presentation/layer/alert/confirmation ID、树查询、手动 completion 和 `@testable` 的合并搜索为零命中。逐项查看 public 声明和 public extension，未发现内部完成入口被公开。
- `NavigationPresentationHandle` 仅公开 `dismiss()`，私有 lifetime、weak Router；公开 `NavigationStackID` 是业务栈标识。Core Endpoint 的内部记录仅配对一次呈现，没有业务对象注册／查找接口。
- Coordinator 不保存集中会话字典；年份、下载详情、preview 的 feature 各持当前资源；历史/debug split 由容器 `@State` 持状态。宽搜索中的 weak、Dictionary、filter、ObjectIdentifier 均已按上下文核对，未发现替代 weak registry 或扫描导航树清理业务资源。
- [普通 import 验证脚本](../../../../../Scripts/validate_navigation_public_api.py) 与 [fixtures](../../../../../Scripts/NavigationCoreAPI/Positive.swift) 保留正向控制、18 个精确诊断负例和 module hash。本记录只确认源码与验证机制，不把未执行的编译当作通过。
- App/hosted tests 的业务 imports 均由共享 UI product 的依赖闭包覆盖；独立 XCUITest 仅 import XCTest、只依赖 App。两个 physical 文件由 SwiftPM 排除并归项目 hosted target 编译。
- 重新生成工程后只读确认 2 个项目测试 + 6 个唯一 package 测试，均启用；独立 UI target 的 TEST_TARGET_NAME、Swift 6/MainActor 正确。TestAction 使用独立环境，启用 `PACKAGE_RESOURCE_BUNDLE_PATH=$(BUILT_PRODUCTS_DIR)`。修复脚本保留项目引用的 UUID／SelectedTests／属性，并通过去重与重复执行幂等 fixture。

可复现搜索（仓库根执行；零命中时 rg 退出码 1 正常）：

```sh
rg -n 'yearPickerSessions|alertMessages|historyStates|downloadPreviewSessions|debugSplitStates|presentationSessionIDs|releaseDismissedContexts|retainedPresentationRoutes|alertRoutes|NavigationPresentationID|NavigationLayerID|NavigationAlertID|NavigationConfirmationID|presentedNode|frontmostPresentationNode|presentationDidDismiss|alertDidDismiss|@testable' Sources/ChineseCalendarUI Apps/iOSApp --glob '*.swift' --glob '!**/Tests/**'
rg -n '^\s*public extension' Sources/NavigationCore --glob '*.swift'
rg -n 'weak|Weak|registry|Registry|NSMapTable|Dictionary|removeAll|\.filter|\.compactMap|ObjectIdentifier' Sources/ChineseCalendarUI --glob '*.swift' --glob '!**/Tests/**'
```

## 00:19 定向测试构建的链接结论

[linkage.json](linkage.json) 保存本轮 binary 的 mtime、SHA256、LC_UUID、load command、精确符号和 LinkFileList hash；不复制临时完整日志。

| 两个 Persistence 类型的各项符号 | App 定义数 | Hosted xctest 定义数 | 共享 UI framework 定义数 |
| --- | ---: | ---: | ---: |
| `ChineseLunarMonth` metadata accessor／nominal descriptor | 各 0 | 各 0 | 各 1 |
| `ChineseCalendarFullSeedStoreInstallError` metadata accessor／nominal descriptor | 各 0 | 各 0 | 各 1 |

- App 与 hosted LinkFileList 没有重复加入 UI、Logging、Persistence、Core、Localization、Data、NavigationCore 的静态对象文件，二者引用同一个 UI framework `@rpath`。
- 源 UI framework 与两份嵌入副本 LC_UUID 相同；嵌入签名后的整体 hash 差异已单独记录。未使用 Products 根目录遗留的旧 package test bundle。
- 本轮 console 的项目模块重复实现信息为 0；6 次聚合文本均来自系统 `UIAccessibilityLoaderWebShared` 在 WebKit/WebCore accessibility bundle 的同一警告。
- 本结论只确认本轮四个 metadata 符号的静态重复已消除。普通 Run 可以将 UI 的完整传递闭包静态链接进 App；不能把这份测试构建证据泛化为普通 Build 或后续全量结果。
