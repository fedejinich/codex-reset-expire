import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var dashboardWindowController: DashboardWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let tokenProvider = FileAuthTokenProvider()
        let client = ResetCreditsClient(tokenProvider: tokenProvider)
        let store = ResetCreditsStore(client: client)

        let statusBarController = StatusBarController(store: store)
        self.statusBarController = statusBarController
        statusBarController.start()

        let dashboardWindowController = DashboardWindowController(store: store)
        self.dashboardWindowController = dashboardWindowController
        dashboardWindowController.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusBarController?.stop()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        dashboardWindowController?.show()
        return true
    }
}
