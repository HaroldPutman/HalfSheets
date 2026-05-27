import CoreGraphics
import Foundation

struct PageSettings: Equatable {
    var splitFromTop: CGFloat = 0.5
    var topCrop: CGFloat = 0
    var bottomCrop: CGFloat = 0
}

enum PageLayoutMath {
    /// Minimum height for each exported half sheet, as a fraction of the full page.
    static let minHalf: CGFloat = 0.05

    /// Exported top half height as a fraction of the full page.
    static func topHalfFraction(topCrop: CGFloat, split: CGFloat) -> CGFloat {
        max(0, split - topCrop)
    }

    /// Exported bottom half height as a fraction of the full page.
    static func bottomHalfFraction(bottomCrop: CGFloat, split: CGFloat) -> CGFloat {
        max(0, (1 - bottomCrop) - split)
    }

    static func clampTopCrop(_ value: CGFloat, split: CGFloat, bottomCrop: CGFloat) -> CGFloat {
        let maxTop = split - minHalf
        return min(max(0, maxTop), max(0, value))
    }

    static func clampBottomCrop(_ value: CGFloat, split: CGFloat, topCrop: CGFloat) -> CGFloat {
        let maxBottom = (1 - split) - minHalf
        return min(max(0, maxBottom), max(0, value))
    }

    static func clampSplit(_ value: CGFloat, topCrop: CGFloat, bottomCrop: CGFloat) -> CGFloat {
        let lower = topCrop + minHalf
        let upper = (1 - bottomCrop) - minHalf
        guard lower <= upper else { return (lower + upper) / 2 }
        return min(upper, max(lower, value))
    }

    static func normalized(_ settings: PageSettings) -> PageSettings {
        var s = settings
        s.topCrop = clampTopCrop(s.topCrop, split: s.splitFromTop, bottomCrop: s.bottomCrop)
        s.bottomCrop = clampBottomCrop(s.bottomCrop, split: s.splitFromTop, topCrop: s.topCrop)
        s.splitFromTop = clampSplit(s.splitFromTop, topCrop: s.topCrop, bottomCrop: s.bottomCrop)
        s.topCrop = clampTopCrop(s.topCrop, split: s.splitFromTop, bottomCrop: s.bottomCrop)
        s.bottomCrop = clampBottomCrop(s.bottomCrop, split: s.splitFromTop, topCrop: s.topCrop)
        return s
    }
}
