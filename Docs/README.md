# Docs

项目规范、领域设计与工具操作文档。编写代码和 review 按任务读取同一份专题规范。

## 编写与审查共用规范

- [通用规范](Conventions/Common.md)：代码注释使用中文，以及日志入口、分类、级别和隐私约定。
- [SwiftUI](Conventions/SwiftUI.md)：子 View、私有属性／函数的拆分边界，`body` 结构和展示常量。

新增简短的通用规则放进 `Conventions/Common.md`；像 SwiftUI 这样需要详细说明的专题再单独成文，放在 `Conventions/`，在这里添加索引，并在 `AGENTS.md` 说明何时读取。每项规则只维护一个来源；模块 README 和技能引用对应文档。尚未落地的方案留在 Issue 或提案中。

## 任务方案与结果

- [任务文档约定与模板](Tasks/README.md)：重要任务的方案、决策理由、实现结果和验收证据；小改动沿用 Issue / PR。
- 已有 [验证记录](validation/) 继续保留，新任务按上述约定组织，不补造历史方案。

## 工具操作

- [Agent 工作流](agent-workflows.md)：Xcode 项目上下文、工具选择和 Simulator 浏览器镜像操作要求。

## 领域模型与页面设计

- [日历数据模型](<data model/data-model-calendar.md>)：日记录、公历表达和农历年月日模型。
- [朝代数据模型](<data model/data-model-dynasty.md>)：朝代区间、正统时间归属和日期精度。
- [历史 Tab](history-tab-rewrite-requirement.md)：以朝代为入口的历史 Tab 流程、组件边界和验收标准。
- [干支与生肖](<data model/sexagenary-cycle-and-zodiac.md>)：干支、生肖、闰月、历史特殊年份和数据库唯一键。
- [SwiftData 种子库](<data model/swiftdata-seed-store.md>)：种子库生成与集成。
- [年号和皇帝](<data model/年号和皇帝.md>)：SwiftData 模型与关系约束。
