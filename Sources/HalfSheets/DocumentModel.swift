import Foundation
import PDFKit
import SwiftUI

final class DocumentModel: ObservableObject {
    @Published var pdfDocument: PDFDocument?
    @Published var sourceURL: URL?
    @Published var pageSettings: [PageSettings] = []
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
        pageSettings = Array(repeating: PageSettings(), count: document.pageCount)
        focusedPageIndex = 0
    }

    func clear() {
        pdfDocument = nil
        sourceURL = nil
        pageSettings = []
        focusedPageIndex = 0
        loadError = nil
    }

    func focusPage(_ index: Int) {
        guard index >= 0, index < pageSettings.count else { return }
        focusedPageIndex = index
    }

    func nudgeFocusedPage(by delta: CGFloat) {
        guard focusedPageIndex >= 0, focusedPageIndex < pageSettings.count else { return }
        var settings = pageSettings[focusedPageIndex]
        settings.splitFromTop += delta
        pageSettings[focusedPageIndex] = PageLayoutMath.normalized(settings)
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

    func settings(forPage index: Int) -> PageSettings {
        guard index >= 0, index < pageSettings.count else { return PageSettings() }
        return pageSettings[index]
    }

    func setSettings(_ settings: PageSettings, forPage index: Int) {
        guard index >= 0, index < pageSettings.count else { return }
        pageSettings[index] = PageLayoutMath.normalized(settings)
    }

    func splitRatio(forPage index: Int) -> CGFloat {
        settings(forPage: index).splitFromTop
    }

    func setSplitRatio(_ ratio: CGFloat, forPage index: Int) {
        var settings = settings(forPage: index)
        settings.splitFromTop = ratio
        setSettings(settings, forPage: index)
    }
}
