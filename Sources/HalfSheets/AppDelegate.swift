import AppKit

/// SPM `swift run` launches a bare executable, not a .app bundle. Without a regular
/// activation policy the process won't take keyboard focus or show a proper menu bar.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        activateAsForegroundApp()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        activateAsForegroundApp()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows where !window.isVisible {
                window.makeKeyAndOrderFront(nil)
            }
        }
        activateAsForegroundApp()
        return true
    }

    private func activateAsForegroundApp() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
