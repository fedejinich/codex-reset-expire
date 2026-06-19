import AppKit

enum AppLinks {
    static func openCodexAnalytics() {
        guard let url = URL(string: "https://chatgpt.com/codex/cloud/settings/analytics#usage") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
