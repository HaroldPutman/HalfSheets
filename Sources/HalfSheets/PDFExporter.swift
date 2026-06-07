import CoreGraphics
import Foundation
import PDFKit

enum PDFExporter {
    static func export(
        document: PDFDocument,
        pageSettings: [PageSettings]
    ) -> PDFDocument? {
        let output = PDFDocument()

        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let settings = index < pageSettings.count
                ? PageLayoutMath.normalized(pageSettings[index])
                : PageSettings()

            let topEnd = settings.topCrop
            let split = settings.splitFromTop
            let bottomStart = 1 - settings.bottomCrop

            if !settings.isSplit {
                if let keptPage = croppedPage(from: page, fromTop: topEnd, toTop: bottomStart) {
                    output.insert(keptPage, at: output.pageCount)
                }
                continue
            }

            if let topPage = croppedPage(from: page, fromTop: topEnd, toTop: split) {
                output.insert(topPage, at: output.pageCount)
            }
            if let bottomPage = croppedPage(from: page, fromTop: split, toTop: bottomStart) {
                output.insert(bottomPage, at: output.pageCount)
            }
        }

        return output.pageCount > 0 ? output : nil
    }

    /// Renders an upright crop of the visually displayed page into a new PDF page.
    private static func croppedPage(from page: PDFPage, fromTop: CGFloat, toTop: CGFloat) -> PDFPage? {
        guard let cgPage = page.pageRef else { return nil }

        let display = PageGeometry.displaySize(for: page)
        let from = min(fromTop, toTop)
        let to = max(fromTop, toTop)
        let cropWidth = display.width
        let cropHeight = (to - from) * display.height
        guard cropWidth > 1, cropHeight > 1 else { return nil }

        let data = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: cropWidth, height: cropHeight)

        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else { return nil }

        context.beginPDFPage(nil)
        context.saveGState()
        context.translateBy(
            x: 0,
            y: PageGeometry.verticalCropOffset(for: page, fromTop: from, toTop: to)
        )
        context.concatenate(page.transform(for: .mediaBox))
        context.drawPDFPage(cgPage)
        context.restoreGState()
        context.endPDFPage()
        context.closePDF()

        guard let doc = PDFDocument(data: data as Data),
              let newPage = doc.page(at: 0)
        else { return nil }

        return newPage
    }
}
