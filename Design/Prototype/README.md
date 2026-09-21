# 中华历 iOS 网页原型

这是用于规划中华历 iOS 视觉语言、页面结构和导航流程的代码驱动原型。原型现已新增第二个 Tab 的重构流程：从朝代目录进入朝代详情，再分别查看帝王、年号和朝代起讫资料。它与 `Apps/` 中的真实 App、`Sources/` 中的共享 Swift Package 相互独立，不参与 Xcode 构建，也不替代 Simulator、Dynamic Type、VoiceOver 或 Safe Area 验证。

## 启动与构建

项目固定使用 Node.js 24；进入目录后可通过 `nvm use` 读取 `.nvmrc`。

```bash
cd Design/Prototype
nvm use
npm install
npm run dev
```

Vite 会打印本地访问地址。生产构建使用：

```bash
npm run build
npm run preview
```

生成的 `dist/` 和依赖目录 `node_modules/` 已在仓库根目录 `.gitignore` 中忽略。

## 当前能力

- 在同一流程画布中查看朝代目录、朝代详情、帝王列表、年号列表、朝代起讫与大事、年号详情六个真实 Screen。
- 朝代详情是资料枢纽；“16 位皇帝”“17 个年号”“276 年”三个统计项都是独立的可点击入口。
- 帝王列表呈现 16 位皇帝及 17 段纪年的对应关系；年号列表包含 17 个完整样例，点击任一年号进入详情。
- 朝代起讫页面分别说明自称边界、正统期和关键边界事件，不把年精度补成具体日期。
- 用 `push` 和 `pop` 连线标明前进及返回关系，连线从真实按钮边界动态测量。
- 使用仓库已处理数据中的明朝皇帝、年号、使用年份和沿革说明作为原型样例。
- 在浅色/深色主题与紧凑/常规画板之间切换。
- 颜色、字体、间距、圆角和阴影由 CSS Variables 集中管理。

## 目录职责

```text
src/
├── design-system/
│   ├── tokens.css          # 与主题无关的 Design Tokens 单一来源
│   ├── themes.css          # 深色主题与尺寸覆盖
│   └── components/         # Button、Card、NavigationBar 等基础组件
├── screens/                # 与 SwiftUI 页面职责对应的页面原型
├── flows/                  # 页面、触发动作与呈现方式的结构化数据和流程图
└── prototype/              # 原型工作台、画板状态和页面编排
```

组件命名对应这次信息架构中的 Screen：`HistoryHomeScreen` 是朝代目录，`DynastyDetailScreen` 是朝代总览，`EmperorListScreen`、`ReignEraListScreen` 和 `DynastySpanDetailScreen` 是三个资料分支，`ReignEraDetailScreen` 是年号详情。网页原型不导入或解析 Swift 源码，样例数据在 `historyData.ts` 中显式维护。

## 修改全局样式

编辑 `src/design-system/tokens.css` 中的变量即可同步更新所有使用该 token 的页面。例如修改 `--color-accent` 会同时更新选中日期、按钮、页面流程线和年份勾选；修改 `--radius-large` 会同步更新所有大卡片和工作台面板。

主题只覆盖有差异的变量，位于 `src/design-system/themes.css`。不要在页面组件中硬编码主题颜色。

## 新增页面

1. 在 `src/flows/navigationFlow.ts` 的 `ScreenId` 和 `screenNames` 中注册页面。
2. 在 `src/screens/` 新建页面组件，优先组合 `design-system/components/` 中的复用组件。
3. 在 `PrototypeApp.tsx` 中把页面接入流程画布，并在真实触发按钮上标记对应的 `data-transition-id`。
4. 在 `navigationFlow` 数组中记录来源、目标、触发动作和 `state`、`sheet`、`dismiss`、`fullScreenCover` 或 `tab` 呈现方式。
5. 如需新视觉值，优先新增语义化 token，而不是在页面中复制常量。

页面流程数据是可点击原型和直接连线的共同约定。修改跳转时应同时更新交互处理、按钮的 `data-transition-id` 与 `navigationFlow`，避免三者含义漂移。
