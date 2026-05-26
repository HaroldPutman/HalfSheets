import Foundation
import PDFKit
import SwiftUI

final class DocumentModel: ObservableObject {
    @Published var pdfDocument: PDFDocument?
    @Published var sourceURL: URL?
    @Published var splitRatios: [CGFloat] = []
    @Published var focusedPageIndex: Int = 0
    @Published var loadError: String?

    private static let nudgeStep: CGFloat = 0.005
    private static let coarseNudgeStep: CGFloat = 0.02

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
        focusedPageIndex = 0
    }

    func clear() {
        pdfDocument = nil
        sourceURL = nil
        splitRatios = []
        focusedPageIndex = 0
        loadError = nil
    }

    func focusPage(_ index: Int) {
        guard index >= 0, index < splitRatios.count else { return }
        focusedPageIndex = index
    }

    func nudgeFocusedPage(by delta: CGFloat) {
        guard focusedPageIndex >= 0, focusedPageIndex < splitRatios.count else { return }
        setSplitRatio(splitRatios[focusedPageIndex] + delta, forPage: focusedPageIndex)
    }

    func nudgeFocusedPageUp(coarse: Bool = false) {
        let step = coarse ? Self.coarseNudgeStep : Self.nudgeStep
        nudgeFocusedPage(by: -step)
    }

    func nudgeFocusedPageDown(coarse: Bool = false) {
        let step = coarse ? Self.coarseNudgeStep : Self.nudgeStep
        nudgeFocusedPage(by: step)
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
