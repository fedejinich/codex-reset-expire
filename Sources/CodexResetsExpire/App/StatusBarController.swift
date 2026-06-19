import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private static let refreshInterval: TimeInterval = 30 * 60

    private let store: ResetCreditsStore
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private var isStopped = false

    init(store: ResetCreditsStore) {
        self.store = store
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        super.init()

        configureStatusItem()
        configurePopover()
        bindStore()
    }

    func start() {
        store.refresh()
        let refreshTimer = Timer(timeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.store.refresh()
            }
        }
        RunLoop.main.add(refreshTimer, forMode: .common)
        self.refreshTimer = refreshTimer

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    func stop() {
        guard !isStopped else {
            return
        }

        isStopped = true
        refreshTimer?.invalidate()
        refreshTimer = nil
        cancellables.removeAll()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        closePopover()
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(
            systemSymbolName: "arrow.triangle.2.circlepath.circle.fill",
            accessibilityDescription: "Codex Resets"
        )
        button.image?.isTemplate = true
        button.imagePosition = .imageLeading
        button.target = self
        button.action = #selector(togglePopover)
        button.toolTip = store.tooltip()
        updateStatusItem()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 372, height: 420)
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(
                store: store,
                actions: PopoverActions(
                    refresh: { [weak self] in self?.store.refresh() },
                    openCodex: { Self.openCodexAnalytics() },
                    hide: { [weak self] in self?.hideApp() },
                    quit: { NSApplication.shared.terminate(nil) }
                )
            )
        )
    }

    private func bindStore() {
        store.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItem()
            }
            .store(in: &cancellables)
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.title = " Codex \(store.statusTitle())"
        button.toolTip = store.tooltip()
        button.image = NSImage(
            systemSymbolName: store.statusSymbolName(),
            accessibilityDescription: "Codex Resets"
        )
        button.image?.isTemplate = true
    }

    @objc
    private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    @objc
    private func handleWake() {
        store.refresh()
    }

    private func showPopover() {
        guard let button = statusItem.button else {
            return
        }

        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func closePopover() {
        popover.performClose(nil)
    }

    private func hideApp() {
        closePopover()
        NSApp.hide(nil)
    }

    private static func openCodexAnalytics() {
        if let url = URL(string: "https://chatgpt.com/codex/cloud/settings/analytics#usage") {
            NSWorkspace.shared.open(url)
        }
    }
}
