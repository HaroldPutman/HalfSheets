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

            let mediaBox = page.bounds(for: .mediaBox)
            let height = mediaBox.height
            let maxY = mediaBox.maxY
            let minY = mediaBox.minY

            let topCropY = maxY - height * settings.topCrop
            let splitY = maxY - height * settings.splitFromTop
            let bottomCropY = minY + height * settings.bottomCrop

            let topRect = CGRect(
                x: mediaBox.minX,
                y: splitY,
                width: mediaBox.width,
                height: topCropY - splitY
            )
            let bottomRect = CGRect(
                x: mediaBox.minX,
                y: bottomCropY,
                width: mediaBox.width,
                height: splitY - bottomCropY
            )

            if let topPage = croppedPage(from: page, cropRect: topRect) {
                output.insert(topPage, at: output.pageCount)
            }
            if let bottomPage = croppedPage(from: page, cropRect: bottomRect) {
                output.insert(bottomPage, at: output.pageCount)
            }
        }

        return output.pageCount > 0 ? output : nil
    }

    private static func croppedPage(from page: PDFPage, cropRect: CGRect) -> PDFPage? {
        guard cropRect.width > 1, cropRect.height > 1,
              let cgPage = page.pageRef
        else { return nil }

        let data = NSMutableData()
        var mediaBox = CGRect(
            x: 0,
            y: 0,
            width: cropRect.width,
            height: cropRect.height
        )

        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else { return nil }

        context.beginPDFPage(nil)
        context.saveGState()
        context.translateBy(x: -cropRect.origin.x, y: -cropRect.origin.y)
        context.clip(to: cropRect)
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
