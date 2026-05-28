import CoreGraphics
import Foundation

struct PageSettings: Equatable {
    var splitFromTop: CGFloat = 0.5
    var topCrop: CGFloat = 0
    var bottomCrop: CGFloat = 0
    /// When false, export this page as a single sheet (crops still apply).
    var isSplit: Bool = true
}

enum PageLayoutMath {
    /// Minimum height for each exported half sheet, as a fraction of the full page.
    static let minHalf: CGFloat = 0.05

    /// Dragging the split line within this distance of a crop edge turns splitting off.
    static let uncutSnapThreshold: CGFloat = 0.03

    /// Exported top half height as a fraction of the full page.
    static func topHalfFraction(topCrop: CGFloat, split: CGFloat) -> CGFloat {
        max(0, split - topCrop)
    }

    /// Exported bottom half height as a fraction of the full page.
    static func bottomHalfFraction(bottomCrop: CGFloat, split: CGFloat) -> CGFloat {
        max(0, (1 - bottomCrop) - split)
    }

    /// Kept page height when not split, as a fraction of the full page.
    static func uncutKeptFraction(topCrop: CGFloat, bottomCrop: CGFloat) -> CGFloat {
        max(0, 1 - topCrop - bottomCrop)
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

        if s.isSplit {
            s.topCrop = clampTopCrop(s.topCrop, split: s.splitFromTop, bottomCrop: s.bottomCrop)
            s.bottomCrop = clampBottomCrop(s.bottomCrop, split: s.splitFromTop, topCrop: s.topCrop)
            s.splitFromTop = clampSplit(s.splitFromTop, topCrop: s.topCrop, bottomCrop: s.bottomCrop)
            s.topCrop = clampTopCrop(s.topCrop, split: s.splitFromTop, bottomCrop: s.bottomCrop)
            s.bottomCrop = clampBottomCrop(s.bottomCrop, split: s.splitFromTop, topCrop: s.topCrop)
        } else {
            let maxCrop = 1 - minHalf
            s.topCrop = min(max(0, s.topCrop), maxCrop)
            s.bottomCrop = min(max(0, s.bottomCrop), maxCrop - s.topCrop)
            s.topCrop = min(s.topCrop, maxCrop - s.bottomCrop)
        }

        return s
    }

    /// After dragging the split line to an edge, turn splitting off for this page.
    static func shouldSnapToUncut(split: CGFloat, topCrop: CGFloat, bottomCrop: CGFloat) -> Bool {
        let lower = topCrop + uncutSnapThreshold
        let upper = (1 - bottomCrop) - uncutSnapThreshold
        return split <= lower || split >= upper
    }
}
