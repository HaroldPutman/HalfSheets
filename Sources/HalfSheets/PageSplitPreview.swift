import AppKit
import PDFKit
import SwiftUI

struct PageSplitPreview: View {
    let page: PDFPage
    let pageNumber: Int
    @Binding var splitRatioFromTop: CGFloat

    private var pageAspect: CGFloat {
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.height > 0 else { return 8.5 / 11 }
        return bounds.width / bounds.height
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Page \(pageNumber)")
                    .font(.headline)
                Spacer()
                Text("Top: \(percent(splitRatioFromTop)) · Bottom: \(percent(1 - splitRatioFromTop))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            GeometryReader { geometry in
                let layout = pageLayout(in: geometry.size)

                ZStack(alignment: .topLeading) {
                    pageImage(size: layout.contentSize)
                        .frame(width: layout.contentSize.width, height: layout.contentSize.height)
                        .position(
                            x: layout.origin.x + layout.contentSize.width / 2,
                            y: layout.origin.y + layout.contentSize.height / 2
                        )

                    splitOverlay(layout: layout)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(splitDragGesture(layout: layout))
            }
            .aspectRatio(pageAspect, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.secondary.opacity(0.35))
            }
        }
    }

    private func pageLayout(in containerSize: CGSize) -> PageLayout {
        let aspect = pageAspect
        let containerAspect = containerSize.width / max(containerSize.height, 1)

        let contentSize: CGSize
        if containerAspect > aspect {
            let height = containerSize.height
            contentSize = CGSize(width: height * aspect, height: height)
        } else {
            let width = containerSize.width
            contentSize = CGSize(width: width, height: width / aspect)
        }

        let origin = CGPoint(
            x: (containerSize.width - contentSize.width) / 2,
            y: (containerSize.height - contentSize.height) / 2
        )
        return PageLayout(origin: origin, contentSize: contentSize)
    }

    @ViewBuilder
    private func splitOverlay(layout: PageLayout) -> some View {
        let lineY = layout.origin.y + layout.contentSize.height * splitRatioFromTop
        let lineCenterX = layout.origin.x + layout.contentSize.width / 2
        let handleX = layout.origin.x + 8

        ZStack {
            Rectangle()
                .fill(Color.red)
                .frame(width: layout.contentSize.width, height: 1)
                .position(x: lineCenterX, y: lineY)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.red)
                .frame(width: 12, height: 24)
                .overlay {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                .position(x: handleX, y: lineY)
        }
        .allowsHitTesting(false)
    }

    private func splitDragGesture(layout: PageLayout) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let localY = value.location.y - layout.origin.y
                let ratio = localY / layout.contentSize.height
                splitRatioFromTop = min(0.9, max(0.1, ratio))
            }
    }

    private func pageImage(size: CGSize) -> some View {
        let thumbnail = page.thumbnail(of: size, for: .mediaBox)
        return Image(nsImage: thumbnail)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
    }

    private func percent(_ value: CGFloat) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

private struct PageLayout {
    let origin: CGPoint
    let contentSize: CGSize
}
