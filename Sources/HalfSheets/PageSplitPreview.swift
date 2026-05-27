import AppKit
import PDFKit
import SwiftUI

struct PageSplitPreview: View {
    let page: PDFPage
    let pageNumber: Int
    let isFocused: Bool
    let onSelect: () -> Void
    @Binding var pageSettings: PageSettings

    @State private var liveSettings: PageSettings?
    @State private var activeDrag: ActiveDrag?

    private var display: PageSettings { liveSettings ?? pageSettings }

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
                Text(halfSizeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            GeometryReader { geometry in
                let layout = pageLayout(in: geometry.size)

                ZStack(alignment: .topLeading) {
                    pageCanvas(layout: layout, settings: display)
                    Color.clear
                        .frame(width: layout.contentSize.width, height: layout.contentSize.height)
                        .contentShape(Rectangle())
                        .gesture(pageDragGesture(layout: layout))
                        .position(
                            x: layout.origin.x + layout.contentSize.width / 2,
                            y: layout.origin.y + layout.contentSize.height / 2
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(pageAspect, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isFocused ? Color.accentColor.opacity(0.8) : Color.secondary.opacity(0.35),
                        lineWidth: isFocused ? 2 : 1
                    )
            }
            .onTapGesture {
                onSelect()
            }
        }
    }

    private var halfSizeLabel: String {
        let top = PageLayoutMath.topHalfFraction(
            topCrop: display.topCrop,
            split: display.splitFromTop
        )
        let bottom = PageLayoutMath.bottomHalfFraction(
            bottomCrop: display.bottomCrop,
            split: display.splitFromTop
        )
        return "Top: \(percent(top)) · Bottom: \(percent(bottom))"
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
    private func pageCanvas(layout: PageLayout, settings: PageSettings) -> some View {
        let width = layout.contentSize.width
        let height = layout.contentSize.height
        let center = CGPoint(
            x: layout.origin.x + width / 2,
            y: layout.origin.y + height / 2
        )

        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor))

            CachedPageThumbnail(page: page, size: layout.contentSize)
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            cropShadeOverlay(layout: layout, settings: settings)
            lineOverlay(layout: layout, settings: settings)
        }
        .frame(width: width, height: height)
        .position(x: center.x, y: center.y)
    }

    @ViewBuilder
    private func cropShadeOverlay(layout: PageLayout, settings: PageSettings) -> some View {
        let width = layout.contentSize.width
        let height = layout.contentSize.height

        if settings.topCrop > 0.001 {
            let topHeight = height * settings.topCrop
            CropShadePattern()
                .frame(width: width, height: topHeight)
                .position(x: width / 2, y: topHeight / 2)
        }

        if settings.bottomCrop > 0.001 {
            let bottomHeight = height * settings.bottomCrop
            CropShadePattern()
                .frame(width: width, height: bottomHeight)
                .position(x: width / 2, y: height - bottomHeight / 2)
        }
    }

    @ViewBuilder
    private func lineOverlay(layout: PageLayout, settings: PageSettings) -> some View {
        let width = layout.contentSize.width
        let height = layout.contentSize.height
        let topCropY = max(2, height * settings.topCrop)
        let splitY = height * settings.splitFromTop
        let bottomCropY = min(height - 2, height * (1 - settings.bottomCrop))

        ZStack {
            cropLine(width: width, y: topCropY)
            cropHandle.position(x: 8, y: topCropY)
            cropHandle.position(x: width - 8, y: topCropY)

            splitLine(width: width, y: splitY)
            splitHandle.position(x: 8, y: splitY)
            splitHandle.position(x: width - 8, y: splitY)

            cropLine(width: width, y: bottomCropY)
            cropHandle.position(x: 8, y: bottomCropY)
            cropHandle.position(x: width - 8, y: bottomCropY)
        }
        .allowsHitTesting(false)
        .animation(nil, value: settings)
    }

    private func cropLine(width: CGFloat, y: CGFloat) -> some View {
        Rectangle()
            .fill(Color.blue)
            .frame(width: width, height: 3)
            .position(x: width / 2, y: y)
    }

    private func splitLine(width: CGFloat, y: CGFloat) -> some View {
        Rectangle()
            .fill(Color.red)
            .frame(width: width, height: 2)
            .position(x: width / 2, y: y)
    }

    private var cropHandle: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.blue)
            .frame(width: 12, height: 24)
            .overlay {
                Image(systemName: "arrow.up.and.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
    }

    private var splitHandle: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.red)
            .frame(width: 12, height: 24)
            .overlay {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
    }

    private func pageDragGesture(layout: PageLayout) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                onSelect()
                var settings = liveSettings ?? pageSettings
                let height = layout.contentSize.height
                let fraction = min(1, max(0, value.location.y / height))

                if activeDrag == nil {
                    activeDrag = pickDragTarget(fraction: fraction, settings: settings)
                }

                switch activeDrag {
                case .topCrop:
                    settings.topCrop = PageLayoutMath.clampTopCrop(
                        fraction,
                        split: settings.splitFromTop,
                        bottomCrop: settings.bottomCrop
                    )
                case .split:
                    settings.splitFromTop = PageLayoutMath.clampSplit(
                        fraction,
                        topCrop: settings.topCrop,
                        bottomCrop: settings.bottomCrop
                    )
                case .bottomCrop:
                    settings.bottomCrop = PageLayoutMath.clampBottomCrop(
                        1 - fraction,
                        split: settings.splitFromTop,
                        topCrop: settings.topCrop
                    )
                case nil:
                    break
                }

                liveSettings = PageLayoutMath.normalized(settings)
            }
            .onEnded { _ in
                if let liveSettings {
                    pageSettings = liveSettings
                }
                self.liveSettings = nil
                activeDrag = nil
            }
    }

    private func pickDragTarget(fraction: CGFloat, settings: PageSettings) -> ActiveDrag {
        let edgeZone: CGFloat = 0.14
        if fraction < edgeZone { return .topCrop }
        if fraction > 1 - edgeZone { return .bottomCrop }

        let candidates: [(ActiveDrag, CGFloat)] = [
            (.topCrop, abs(fraction - settings.topCrop)),
            (.split, abs(fraction - settings.splitFromTop)),
            (.bottomCrop, abs(fraction - (1 - settings.bottomCrop))),
        ]
        return candidates.min(by: { $0.1 < $1.1 })?.0 ?? .split
    }

    private func percent(_ value: CGFloat) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

private enum ActiveDrag {
    case topCrop
    case split
    case bottomCrop
}

/// Diagonal crosshatch over a semi-transparent fill for cropped-away regions.
private struct CropShadePattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 10
            var path = Path()
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                x += spacing
            }
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color(nsColor: .systemGray).opacity(0.45))
            )
            context.stroke(path, with: .color(.white.opacity(0.35)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

/// Renders the page once per display size; drags must not re-rasterize the PDF.
private struct CachedPageThumbnail: View {
    let page: PDFPage
    let size: CGSize

    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
            } else {
                Color(nsColor: .windowBackgroundColor)
            }
        }
        .task(id: renderKey) {
            guard size.width > 1, size.height > 1 else { return }
            image = page.thumbnail(of: size, for: .mediaBox)
        }
    }

    private var renderKey: String {
        "\(Int(size.width.rounded()))x\(Int(size.height.rounded()))"
    }
}

private struct PageLayout {
    let origin: CGPoint
    let contentSize: CGSize
}
