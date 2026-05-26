import Foundation
import PDFKit

let paths = CommandLine.arguments.dropFirst()
for path in paths {
    guard let doc = PDFDocument(url: URL(fileURLWithPath: path)) else {
        print("Failed: \(path)")
        continue
    }
    print("=== \(path) === pages: \(doc.pageCount)")
    for i in 0..<doc.pageCount {
        guard let p = doc.page(at: i) else { continue }
        print(
            "  \(i + 1): rot=\(p.rotation) media=\(p.bounds(for: .mediaBox)) crop=\(p.bounds(for: .cropBox))"
        )
    }
}
