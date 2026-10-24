import SwiftUI
import UIKit

/// 固定画布与系统特征，运行设备本身不决定基准尺寸。
enum SnapshotAppearance: String {
    case phone
    case tablet
    case dark
    case accessibility

    var size: CGSize {
        self == .tablet ? CGSize(width: 1366, height: 1024) : CGSize(width: 390, height: 844)
    }

    var safeArea: UIEdgeInsets {
        self == .tablet
            ? UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0)
            : UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0)
    }

    var colorScheme: ColorScheme {
        self == .dark ? .dark : .light
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .accessibility ? .accessibility5 : .large
    }
}
