import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let tokenProvider = FileAuthTokenProvider()
        let client = ResetCreditsClient(tokenProvider: tokenProvider)
        let store = ResetCreditsStore(client: client)
        let statusBarController = StatusBarController(store: store)
        self.statusBarController = statusBarController
        statusBarController.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusBarController?.stop()
    }
}
