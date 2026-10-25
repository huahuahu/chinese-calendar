# 换库选择逻辑简化

- 日期：2026-10-25
- 依据：用户对 `prepareSelectionForStoreReplacement` / `restoreSelection` 的评论：“这个逻辑太复杂 删掉吧”。
- 状态：已按评论删除；本补充取代原 AC-04 的跨库保留浏览月份要求。

## 最终行为

删除 `StoreSelectionRestoration`、临时保存字段、换库前查询月份以及换库后恢复月份的分支。数据库身份或 ModelContext 更换时，使用现有失效入口清空选择并重置初始解析标记；新库连接后重新解析页面的原始 landing。同一库内的刷新保留已有浏览选择。

首页 `.today` 重新定位今天；年月入口按新库已有数据解析月或日；精确日入口找不到记录时保持不可用，完整库就绪后可重试。年份选择器的旧 Binding、generation 与 handle 失效逻辑保留。

## 验证范围

调整现有独立容器测试覆盖 base→full、full→base、full→full 重新解析原入口，以及同库刷新、精确日清库后不可用和重新安装后的重试。复验旧年份 Binding 无法写回。真实下载完成与清空操作的 UI 端到端验证仍未补做，不将自动测试描述为交互证明。最新测试和审查结论见 [001-result.md](001-result.md)。
