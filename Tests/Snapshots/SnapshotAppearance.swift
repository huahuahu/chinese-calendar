import SnapshotTesting
import SwiftUI
import UIKit

/// 使用截图库的设备布局，并固定外观、字号和输出比例。
enum SnapshotAppearance: String {
    case phone
    case tablet
    case dark
    case accessibility

    var layout: SwiftUISnapshotLayout {
        .device(config: self == .tablet ? .iPadPro12_9 : .iPhone13)
    }

    var traits: UITraitCollection {
        UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: self == .dark ? .dark : .light),
            UITraitCollection(preferredContentSizeCategory: self == .accessibility
                ? .accessibilityExtraExtraExtraLarge : .large),
            UITraitCollection(displayScale: 1)
        ])
    }

    var colorScheme: ColorScheme {
        self == .dark ? .dark : .light
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .accessibility ? .accessibility5 : .large
    }
}
