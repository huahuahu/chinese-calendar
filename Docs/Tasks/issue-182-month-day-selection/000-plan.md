# 月／日选择与基础数据年月浏览：方案

- 关联：[Issue #182](https://github.com/huahuahu/chinese-calendar/issues/182)
- 状态：可执行
- 更新日期：2026-10-24

## 背景、目标与范围

基础库有真实农历年、月记录，没有逐日记录。当前 CalendarSelection 仅保存日序，CalendarPageView 先要求选中日存在，导致整页空态遮住可用的年月信息。恢复基础库的年月浏览，下载提示仅占日格区域。

遵循 [领域上下文](../../../CONTEXT.md)、[通用规范](../../Conventions/Common.md)、[SwiftUI 规范](../../Conventions/SwiftUI.md)、[导航规范](../../Conventions/Navigation.md) 与[文案规范](../../Conventions/Localization.md)。不修改数据库 schema、NavigationCore 或自动下载策略。

## 方案与决策

- CalendarSelection 只持有 CalendarSelectionValue：真实月 `.month(index:)` 或真实日 `.day(index:)`。索引分别为连续 lunarMonthIndex 与 dayIndex。年份及日的所属月份均通过模型关系推导；selectedDayIndex 只作为只读投影。
- LunarCalendarLanding 保留年／月／日导航意图。年月请求有日时按现有今天优先／边界月份首个可用日规则落日，无日但月存在时落月。不存在的精确日不能回退到任意年月。
- CalendarPageView 根据月或日定位当前月，正常显示头部和日格；只有日粒度显示选中日详情。日格使用现有基础数据空态并明确说明下载后可查看本月每日信息。
- 首页与“今天”在基础库使用当前农历年月和闰月标记匹配数据库的唯一月份。当前日期换算沿用 Core 的 Foundation 现代农历辅助能力；历史导航始终使用数据库记录，不使用 Foundation 重算历史历法。
- CalendarYearFeature 继续拥有选择、年份过渡和年份选择器。换库时清空选择与初始解析标记，新库连接后重新解析页面原始 landing；不保存换库前的月份，也不建立恢复状态。
- 同库刷新保留已有浏览选择。未能解析的精确日请求保持未完成，在新库就绪后重试；精确日入口无对应记录时不降级为月。
- Feature 的生命周期继续位于 calendarStoreContent 的查询重建边界之外；不把 SwiftData 模型跨容器保存。

## 验收标准

| ID | 场景与预期行为 | 验证方式 |
| --- | --- | --- |
| AC-01 | 基础库首页显示当前农历年月，日格局部下载提示，无日详情 | 当前月解析测试、真实基础数据 Preview／Simulator |
| AC-02 | 基础库选年、选月、前后月与跨年正常，使用连续月序 | Resolver／Feature 测试、Simulator |
| AC-03 | 完整库默认日、高亮和日详情保持正常；精确无效日不降级 | Resolver 测试、完整数据 Preview |
| AC-04（已修订） | 换库后重新解析原始入口，同库刷新保留已有选择；精确日不可用时不降级 | 两个独立 ModelContainer 的 Feature 测试、运行交互 |
| AC-05 | 未解析的日请求在完整库中精确重试 | Feature 测试 |
| AC-06 | 年份 Binding／旧会话失效规则保持正确 | 原有 Feature／Presentation 测试 |
| AC-07 | 格式、严格 lint、本地化、相关 iOS 测试与构建通过 | 项目脚本及原生 Xcode MCP |

## 待定事项与后续调整

当前没有待定的产品决策；若当前农历月无法在数据中唯一定位，保持明确不可用状态，不将其他月标为当前月。运行证据与工具限制记入结果文档。

## 2026-10-25 后续调整

当前月定位改用真实月长累计区间；详见[月长补充方案](003-month-daycount-plan.md)及[本轮结果](004-month-daycount-result.md)。本页原有运行证据仍对应此前实现。

用户随后要求删除复杂的换库保存／恢复逻辑，当前决定与验收以上述修订为准；详情见 [005-store-selection-simplification.md](005-store-selection-simplification.md)。
