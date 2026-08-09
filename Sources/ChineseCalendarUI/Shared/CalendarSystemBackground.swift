import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

#if canImport(AppKit)
    import AppKit
#endif

extension ShapeStyle where Self == Color {
    static var calendarSystemBackground: Color {
        #if canImport(UIKit)
            Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
            Color(nsColor: .windowBackgroundColor)
        #else
            Color.white
        #endif
    }
}
