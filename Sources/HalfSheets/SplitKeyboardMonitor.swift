import AppKit
import SwiftUI

/// Intercepts arrow keys while a document is open; SwiftUI focus does not work reliably inside ScrollView.
struct SplitKeyboardMonitor: ViewModifier {
    @ObservedObject var model: DocumentModel
    @State private var eventMonitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear { updateMonitor() }
            .onDisappear { removeMonitor() }
            .onChange(of: model.hasDocument) { _, _ in updateMonitor() }
    }

    private func updateMonitor() {
        if model.hasDocument {
            installMonitor()
        } else {
            removeMonitor()
        }
    }

    private func installMonitor() {
        guard eventMonitor == nil else { return }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard model.hasDocument, NSApp.isActive else { return event }

            let coarse = event.modifierFlags.contains(.shift)
            switch event.keyCode {
            case 126:
                model.nudgeFocusedPageUp(coarse: coarse)
                return nil
            case 125:
                model.nudgeFocusedPageDown(coarse: coarse)
                return nil
            default:
                return event
            }
        }
    }

    private func removeMonitor() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }

}

extension View {
    func splitKeyboardMonitor(model: DocumentModel) -> some View {
        modifier(SplitKeyboardMonitor(model: model))
    }
}
