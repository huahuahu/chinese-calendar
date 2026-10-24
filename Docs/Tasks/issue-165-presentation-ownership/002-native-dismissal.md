# 呈现接口简化

- 日期：2026-10-24
- 状态：已实现并通过本地自动验证，见[结果](003-native-dismissal-result.md)
- 本记录替代 [原方案](000-plan.md) 中按次配置、endpoint／render record 以及所有终止场景恰好通知一次的设计；既有验证证据只适用于原实现。

## 已确认的范围

1. 路由直接携带页面参数，包括 Binding 和业务资源。含引用或 Binding 的路由由创建时确定的稳定 ID 比较和哈希，不读取可变内容；普通值路由保留值语义。
2. 每棵导航树只在根部提供 NavigationHostConfiguration，根、push 和递归模态继承同一配置。删除 present 的 configuration 参数和按次构建工厂。
3. sheet／fullScreenCover 的 onDismiss 直接转发到本次提交的 onDismiss。回调先取走，导航结构完成收尾后调用，防止旧回调清理新请求。拒绝、排队取消和 Router／宿主销毁不补发关闭通知。

移除 NavigationPresentationEndpoint、NavigationPresentationRenderRecord、NavigationModalMount、NavigationModalLifecycleController 和 NavigationHostLifetime。内部只保留定位请求、防重复关闭及已有导航协调所需状态。失效 Context 与 handle 不保活带业务参数的路由。

业务发起方持有流程状态；主动取消或 store 失效时立即撤销结果资格并清理自己的状态。页面路由继续持有退出动画需要的数据。年份选择的来源隔离、一次消费、store 校验和年份过渡保留；下载演示父子页面通过路由共享同一业务 state。

业务 alert 仍用已有原生 alert 宿主，保留关闭后的异步按钮动作、串行排队和离开确认。它的动作完成通知与页面的 SwiftUI onDismiss 分开说明，不新增模态 UIViewController 探针。

## 验收

- 普通调用方仅需路由、可选 onDismiss 和关闭 handle，不接触内部节点与生命周期状态。
- Binding 内容变化不改变路由哈希；相同值的两次新请求拥有不同身份；来源之间结果隔离。
- 正常 sheet／fullScreen 关闭回调一次，旧回调和旧 handle 不影响新请求；未呈现取消释放参数且不通知。
- 关闭后的旧 Context／handle 不保活业务资源；取消与 store 替换不会留下业务 active 字段。
- 根配置用于根、push 和嵌套模态；alert、离开确认、排队与延迟导航继续回归。
- 运行格式、strict lint、Core 与 App 相关测试和 iOS 构建；自动测试与实际手势证据分别记录。
