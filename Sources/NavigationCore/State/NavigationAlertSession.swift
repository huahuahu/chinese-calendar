import Foundation

/// 记录系统提示的实际生命周期，防止数据清空后立即展示下一个提示。
struct NavigationAlertSession {
    let id: UUID
    let isConfirmation: Bool
    var isClosing = false
    var isHandlingCompletion = false
}
