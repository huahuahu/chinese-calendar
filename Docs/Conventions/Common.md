# 通用项目规范

集中维护代码注释、日志等简短的项目规则，供编写和 review 共用。SwiftUI 的专项约定见 [SwiftUI 项目规范](SwiftUI.md)。

## 代码注释

适用于本仓库代码注释的编写、修改和审查，包括行注释、块注释、文档注释（如 Swift 的 `///`）和脚本注释。

### COMMENT-01 — 使用中文

- 新增或修改的说明性代码注释使用中文。API 名称、代码标识符和必要的技术术语可以保留原名；工具指令和必须保留原文的引用不翻译。
- 本规则针对本次新增或修改的注释，不要求批量翻译未改动的既有注释。
- 日志消息属于运行时输出，本规则不规定其语言。

## 日志

适用于本项目 App 和共享 Swift Package 中日志的编写、修改和审查。使用共享的 `ChineseCalendarLogging` 模块。

### 日志入口

优先使用预定义的模块 logger：

```swift
import ChineseCalendarLogging

ChineseCalendarLog.ui.debug("Refreshing calendar home view")
ChineseCalendarLog.persistence.error("Failed to open seed store: \(error.localizedDescription, privacy: .private)")
```

### 分类

- `app`：App 生命周期和平台入口
- `core`：日历领域计算
- `data`：数据仓库和导入数据读取
- `persistence`：SwiftData 存储、种子数据库安装、迁移
- `ui`：共享 SwiftUI 视图和 view model
- `import`：源数据导入脚本和生成产物

只有当模块级过滤太吵时，才创建更细的分类：

```swift
let logger = ChineseCalendarLog.logger(category: "persistence.seed-store")
```

### 级别约定

- `debug`：仅开发时需要的细节、频繁分支、本地值
- `info`：有用但轻量的进度事件
- `notice`：对 App 有意义、值得保留以便排查的问题线索
- `error`：可恢复的失败
- `fault`：程序错误或损坏状态

### 日志内容与隐私

优先记录静态消息和少量标量值。文件路径、选中日期、导入源文本、错误描述默认按私有信息处理，除非明确确认可以公开。

## 验证与维护

- 检查本次改动中的说明性注释是否使用中文，并保留上述必要原文。
- 确认日志使用共享入口、分类与级别符合事件含义、动态信息的隐私标记符合上述要求。修改日志封装本身时，结合 `Sources/ChineseCalendarLogging/Tests` 验证其行为。
- 仅调整本规范时无需构建 App。
