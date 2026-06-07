import CoreGraphics
import PDFKit

/// Maps between visual (upright) page coordinates and PDF media-box space.
enum PageGeometry {
    static func normalizedRotation(_ rotation: Int) -> Int {
        ((rotation % 360) + 360) % 360
    }

    /// Page size as shown in Preview and PDFKit thumbnails (rotation applied).
    static func displaySize(for page: PDFPage) -> CGSize {
        let media = page.bounds(for: .mediaBox)
        switch normalizedRotation(page.rotation) {
        case 90, 270:
            return CGSize(width: media.height, height: media.width)
        default:
            return CGSize(width: media.width, height: media.height)
        }
    }

    static func displayAspect(for page: PDFPage) -> CGFloat {
        let size = displaySize(for: page)
        guard size.height > 0 else { return 8.5 / 11 }
        return size.width / size.height
    }

    /// Y translation before applying `page.transform(for:)` to show the visual
    /// crop span `[fromTop, toTop)` (0 = top, 1 = bottom) in the output page.
    static func verticalCropOffset(
        for page: PDFPage,
        fromTop: CGFloat,
        toTop: CGFloat
    ) -> CGFloat {
        let display = displaySize(for: page)
        let from = min(fromTop, toTop)
        let to = max(fromTop, toTop)
        switch normalizedRotation(page.rotation) {
        case 0:
            return -(1 - to) * display.height
        default:
            return -from * display.height
        }
    }
}
