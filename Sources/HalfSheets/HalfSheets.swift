import AppKit
import SwiftUI
import UniformTypeIdentifiers

@main
struct HalfSheetsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 650)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

struct ContentView: View {
    @StateObject private var model = DocumentModel()
    @State private var isDropTargeted = false
    @State private var exportError: String?

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .navigationTitle(model.sourceURL?.lastPathComponent ?? "HalfSheets")
        .alert("Export Failed", isPresented: exportErrorBinding) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HalfSheets")
                .font(.title2.bold())

            Text("Split letter-size sheet music into two half sheets (8.5″ × 5.5″).")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let url = model.sourceURL {
                Label(url.lastPathComponent, systemImage: "doc.fill")
                    .lineLimit(2)
                    .help(url.path)
            }

            if model.hasDocument {
                Text("\(model.pageCount) page\(model.pageCount == 1 ? "" : "s")")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if model.hasDocument {
                Button("Export PDF…") {
                    exportPDF()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Clear") {
                    model.clear()
                }
            }
        }
        .padding()
        .frame(minWidth: 220, maxWidth: 260)
    }

    @ViewBuilder
    private var detail: some View {
        if model.hasDocument, let document = model.pdfDocument {
            ScrollView {
                LazyVStack(spacing: 28) {
                    ForEach(0..<document.pageCount, id: \.self) { index in
                        if let page = model.page(at: index) {
                            PageSplitPreview(
                                page: page,
                                pageNumber: index + 1,
                                splitRatioFromTop: splitBinding(for: index)
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(nsColor: .controlBackgroundColor))
        } else {
            dropZone
        }
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.5),
                    style: StrokeStyle(lineWidth: 2, dash: [10])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDropTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
                )

            VStack(spacing: 12) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 44))
                    .foregroundStyle(isDropTargeted ? Color.accentColor : .secondary)

                Text("Drop a PDF here")
                    .font(.title2)

                Text("2–5 pages of 8.5″ × 11″ sheet music")
                    .foregroundStyle(.secondary)

                if let error = model.loadError {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding(.top, 8)
                }
            }
            .padding(40)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .onDrop(of: [.pdf, .fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
    }

    private func splitBinding(for index: Int) -> Binding<CGFloat> {
        Binding(
            get: { model.splitRatio(forPage: index) },
            set: { model.setSplitRatio($0, forPage: index) }
        )
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.pdf.identifier) { item, _ in
                let url = item as? URL
                let data = item as? Data
                Task { @MainActor in
                    if let url {
                        model.load(url: url)
                    } else if let data, let temp = writeTemporaryPDF(data) {
                        model.load(url: temp)
                    }
                }
            }
            return true
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                guard let url = item as? URL else { return }
                Task { @MainActor in
                    model.load(url: url)
                }
            }
            return true
        }

        return false
    }

    private func writeTemporaryPDF(_ data: Data) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pdf")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    private func exportPDF() {
        guard let document = model.pdfDocument else { return }
        guard let output = PDFExporter.export(
            document: document,
            splitRatiosFromTop: model.splitRatios
        ) else {
            exportError = "Could not build the output PDF."
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = suggestedExportName()

        guard panel.runModal() == .OK, let url = panel.url else { return }

        if output.write(to: url) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            exportError = "Could not write the file to disk."
        }
    }

    private func suggestedExportName() -> String {
        guard let source = model.sourceURL else { return "HalfSheets.pdf" }
        let base = source.deletingPathExtension().lastPathComponent
        return "\(base)-half-sheets.pdf"
    }

    private var exportErrorBinding: Binding<Bool> {
        Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )
    }
}
