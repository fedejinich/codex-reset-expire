import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private static let refreshInterval: TimeInterval = 30 * 60
    private static let panelWidth: CGFloat = 276

    private let store: ResetCreditsStore
    private let statusItem: NSStatusItem
    private var panel: MenuBarDropdownPanel?
    private var hostingController: NSHostingController<PopoverView>?
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private var isStopped = false

    init(store: ResetCreditsStore) {
        self.store = store
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        configureStatusItem()
        configurePanel()
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
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleShowPopoverNotification),
            name: AppNotifications.showPopover,
            object: AppNotifications.bundleIdentifier
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
        DistributedNotificationCenter.default().removeObserver(self)
        closePanel()
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.image = menuBarImage()
        button.image?.isTemplate = true
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(togglePopover)
        button.toolTip = store.tooltip()
        updateStatusItem()
    }

    private func configurePanel() {
        let hostingController = NSHostingController(
            rootView: PopoverView(
                store: store,
                actions: PopoverActions(
                    refresh: { [weak self] in self?.store.refresh() },
                    openCodex: { AppLinks.openCodexAnalytics() },
                    hide: { [weak self] in self?.closePanel() },
                    quit: { NSApplication.shared.terminate(nil) }
                )
            )
        )
        hostingController.view.frame = NSRect(x: 0, y: 0, width: Self.panelWidth, height: 1)

        let panel = MenuBarDropdownPanel(
            contentRect: NSRect(x: 0, y: 0, width: Self.panelWidth, height: 1),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        panel.contentViewController = hostingController
        panel.hasShadow = true
        panel.isMovable = false
        panel.isOpaque = false
        panel.isReleasedWhenClosed = false
        panel.level = .popUpMenu

        self.hostingController = hostingController
        self.panel = panel
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

        button.title = ""
        button.toolTip = store.tooltip()
        button.image = menuBarImage()
        button.image?.isTemplate = true
    }

    private func menuBarImage() -> NSImage? {
        NSImage(
            systemSymbolName: "arrow.clockwise.circle.fill",
            accessibilityDescription: "Codex reset credits"
        ) ?? NSImage(
            systemSymbolName: "arrow.triangle.2.circlepath.circle.fill",
            accessibilityDescription: "Codex reset credits"
        )
    }

    @objc
    private func togglePopover() {
        if panel?.isVisible == true {
            closePanel()
        } else {
            showPopover()
        }
    }

    @objc
    private func handleWake() {
        store.refresh()
    }

    @objc
    private func handleShowPopoverNotification() {
        showPopover()
    }

    func showPopover() {
        guard let button = statusItem.button else {
            return
        }

        positionPanel(relativeTo: button)
        panel?.makeKeyAndOrderFront(nil)
        installEventMonitors()
    }

    private func closePanel() {
        panel?.orderOut(nil)
        removeEventMonitors()
    }

    private func positionPanel(relativeTo button: NSStatusBarButton) {
        guard let panel, let hostingController = hostingController else {
            return
        }

        let contentSize = fittedPanelSize(hostingController: hostingController)
        let buttonFrame = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero
        let screen = button.window?.screen ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        let x = min(
            max(buttonFrame.midX - contentSize.width / 2, visibleFrame.minX + 8),
            visibleFrame.maxX - contentSize.width - 8
        )
        let y = buttonFrame.minY - contentSize.height

        panel.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: contentSize), display: true)
    }

    private func fittedPanelSize(hostingController: NSHostingController<PopoverView>) -> NSSize {
        hostingController.view.frame = NSRect(x: 0, y: 0, width: Self.panelWidth, height: 1)
        let fittingSize = hostingController.view.fittingSize
        return NSSize(
            width: Self.panelWidth,
            height: min(max(ceil(fittingSize.height), 172), 290)
        )
    }

    private func installEventMonitors() {
        guard localEventMonitor == nil, globalEventMonitor == nil else {
            return
        }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else {
                return event
            }

            if event.window !== self.panel && event.window !== self.statusItem.button?.window {
                self.closePanel()
            }
            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.closePanel()
            }
        }
    }

    private func removeEventMonitors() {
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }

        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
    }

}
