import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
let currentProcessID = ProcessInfo.processInfo.processIdentifier
let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: AppNotifications.bundleIdentifier)

if runningApps.contains(where: { $0.processIdentifier != currentProcessID }) {
    DistributedNotificationCenter.default().postNotificationName(
        AppNotifications.showPopover,
        object: AppNotifications.bundleIdentifier,
        userInfo: nil,
        deliverImmediately: true
    )
    exit(0)
}

app.delegate = delegate
app.run()
