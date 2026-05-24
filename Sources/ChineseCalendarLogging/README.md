# ChineseCalendarLogging

Chinese Calendar 的共享统一日志模块。

优先使用预定义的模块 logger：

```swift
import ChineseCalendarLogging

ChineseCalendarLog.ui.debug("Refreshing calendar home view")
ChineseCalendarLog.persistence.error("Failed to open seed store: \(error.localizedDescription, privacy: .private)")
```

## 分类

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

## 级别约定

- `debug`：仅开发时需要的细节、频繁分支、本地值
- `info`：有用但轻量的进度事件
- `notice`：对 App 有意义、值得保留以便排查的问题线索
- `error`：可恢复的失败
- `fault`：程序错误或损坏状态

优先记录静态消息和少量标量值。文件路径、选中日期、导入源文本、错误描述默认按私有信息处理，除非明确确认可以公开。
