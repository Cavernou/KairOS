import CoreGraphics
import Foundation

enum LayoutMode {
    case portrait
    case landscape

    init(width: CGFloat, height: CGFloat) {
        self = width > height ? .landscape : .portrait
    }

    var isLandscape: Bool {
        self == .landscape
    }
}
