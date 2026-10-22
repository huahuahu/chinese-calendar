# 导航改动合并交付

- 日期：2026-10-22
- PR：[#167](https://github.com/huahuahu/chinese-calendar/pull/167)
- 范围：用户明确要求将原工作区所有改动提交 PR 并合并；包含导航结果与诊断、呈现会话清理、协调状态命名和 alert 语义注释。
- 基线：`2d4f2649942ea63339f6b19f046e1c132df88f34`，已整合历史页原生三栏导航。
- 原始验证：保留两个任务目录中的首次源码快照和测试结果；它们不替代本次整合验证。

## 整合处理

保留主分支历史页详情根、空态根和 Deep Link 换根行为；新增历史调用方迁移至强类型导航结果，测试使用具体枚举断言。历史分栏缓存与 DEBUG 分栏一致，按原栈是否仍被导航树保留判断释放，避免关闭动画期间丢失布局状态；新增嵌套关闭回归测试。原工作区保留，完整改动在独立 worktree 内整合。

## 验证与审查

受测源码 commit 为 `aafdb5b3`，55 个变更 Swift 文件的 SHA-256 见 [integration-source-manifest.json](evidence/integration-source-manifest.json)，环境和工具摘要见 [integration-validation.json](evidence/integration-validation.json)。

- 原生 Xcode `RunAllTests`：原始 xcresult 为 Passed，329 个测试定义、427 个参数化用例执行成功，0 失败、0 跳过、0 runtime warnings。新增历史缓存与生产清理 modifier 的宿主测试通过。
- 原生 MCP 摘要额外列出 2 条随机 UUID 参数的 No result；原始 xcresult 的设备执行计数与控制台明确确认对应测试的 3 个参数用例全部通过。记录该报告差异，不将它当作跳过或失败，也不省略。
- 格式检查：316 文件，0 需修改；严格 lint：305 文件，0 violations；本地化 337 个资源项及 919377 条数据 schema 校验通过。`git diff --check` 与相对 Markdown 链接检查通过。
- 两路专项审查完成：`api-results` 检查结果语义、拒绝前状态保护、日志隐私和调用方合同；`lifecycle` 检查活动／保留树、真实关闭边界、稳定宿主订阅和业务缓存。均基于受测源码 `aafdb5b3`，未发现本次引入的可执行修复项或强制规范违反。协调者已逐份阅读报告并核对相关代码与测试证据。
- 原始工作区全部 64 个变更文件均纳入；整合后的新增适配遵循历史页已有详情根与 Deep Link 合同。与两份方案的 API／自动清理验收一致，未新增导航结构或确认策略。
- 问题处置台账：无 open、deferred 或 required correction。历史缓存的提前释放风险在最终审查前已修复并由新增测试验证；后续仅更新证据文档，源码哈希保持一致。
- 本地逐项报告位于忽略的 `.output/reviews/navigation-integration-20261022/round-01/`。以上为可持久核对的结论；远程 CI 与合并状态以 PR 实际记录为准。

未执行 Preview、手动 Simulator 交互或真机验证；自动宿主测试的关闭完成由测试驱动 Core 入口，不表述为视觉动画验证。
