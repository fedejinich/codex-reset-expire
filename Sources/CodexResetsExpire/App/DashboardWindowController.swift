import AppKit
import SwiftUI

@MainActor
final class DashboardWindowController: NSObject, NSWindowDelegate {
    private let store: ResetCreditsStore
    private var window: NSWindow?

    init(store: ResetCreditsStore) {
        self.store = store
    }

    func show() {
        let window = makeWindow()
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func makeWindow() -> NSWindow {
        if let window {
            return window
        }

        let rootView = PopoverView(
            store: store,
            actions: PopoverActions(
                refresh: { [weak store] in store?.refresh() },
                openCodex: { AppLinks.openCodexAnalytics() },
                hide: { [weak self] in self?.hide() },
                quit: { NSApplication.shared.terminate(nil) }
            )
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 392, height: 452),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Codex Resets"
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.moveToActiveSpace]
        window.contentViewController = NSHostingController(rootView: rootView)
        window.delegate = self

        self.window = window
        return window
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
