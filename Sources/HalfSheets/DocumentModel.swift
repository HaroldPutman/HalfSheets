import Foundation
import PDFKit
import SwiftUI

final class DocumentModel: ObservableObject {
    @Published var pdfDocument: PDFDocument?
    @Published var sourceURL: URL?
    @Published var splitRatios: [CGFloat] = []
    @Published var loadError: String?

    var pageCount: Int { pdfDocument?.pageCount ?? 0 }
    var hasDocument: Bool { pdfDocument != nil }

    func load(url: URL) {
        loadError = nil
        guard url.pathExtension.lowercased() == "pdf" else {
            loadError = "Please drop a PDF file."
            return
        }
        guard let document = PDFDocument(url: url) else {
            loadError = "Could not open the PDF."
            return
        }
        guard document.pageCount > 0 else {
            loadError = "The PDF has no pages."
            return
        }

        pdfDocument = document
        sourceURL = url
        splitRatios = Array(repeating: 0.5, count: document.pageCount)
    }

    func clear() {
        pdfDocument = nil
        sourceURL = nil
        splitRatios = []
        loadError = nil
    }

    func page(at index: Int) -> PDFPage? {
        pdfDocument?.page(at: index)
    }

    func splitRatio(forPage index: Int) -> CGFloat {
        guard index >= 0, index < splitRatios.count else { return 0.5 }
        return splitRatios[index]
    }

    func setSplitRatio(_ ratio: CGFloat, forPage index: Int) {
        guard index >= 0, index < splitRatios.count else { return }
        splitRatios[index] = min(0.9, max(0.1, ratio))
    }
}
