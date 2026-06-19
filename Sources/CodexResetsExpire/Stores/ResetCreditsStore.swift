import Combine
import Foundation

@MainActor
final class ResetCreditsStore: ObservableObject {
    enum State: Equatable {
        case idle
        case loading(CreditsSnapshot?)
        case loaded(CreditsSnapshot)
        case failed(String, CreditsSnapshot?)

        var snapshot: CreditsSnapshot? {
            switch self {
            case .idle:
                return nil
            case let .loading(cachedSnapshot):
                return cachedSnapshot
            case let .loaded(snapshot):
                return snapshot
            case let .failed(_, cachedSnapshot):
                return cachedSnapshot
            }
        }

        var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }
    }

    @Published private(set) var state: State

    private let client: ResetCreditsClientProtocol
    private let cache: CreditsCache<CreditsSnapshot>?
    private let countdownFormatter: CountdownFormatter
    private let dateFormatter: LocalDateFormatter
    private let now: () -> Date

    init(
        client: ResetCreditsClientProtocol,
        cache: CreditsCache<CreditsSnapshot>? = try? CreditsCache<CreditsSnapshot>(),
        countdownFormatter: CountdownFormatter = CountdownFormatter(),
        dateFormatter: LocalDateFormatter = LocalDateFormatter(),
        now: @escaping () -> Date = { Date() }
    ) {
        self.client = client
        self.cache = cache
        self.countdownFormatter = countdownFormatter
        self.dateFormatter = dateFormatter
        self.now = now

        if let cachedSnapshot = try? cache?.load() {
            state = .loaded(cachedSnapshot)
        } else {
            state = .idle
        }
    }

    var currentSnapshot: CreditsSnapshot? {
        state.snapshot
    }

    var isLoading: Bool {
        state.isLoading
    }

    func refresh() {
        Task {
            await refreshNow()
        }
    }

    @discardableResult
    func loadCachedSnapshot() -> CreditsSnapshot? {
        guard let cache else {
            state = .idle
            return nil
        }

        do {
            guard let snapshot = try cache.load() else {
                state = .idle
                return nil
            }

            state = .loaded(snapshot)
            return snapshot
        } catch {
            state = .failed(Self.failureMessage(from: error), nil)
            return nil
        }
    }

    func reset() {
        state = .idle
    }

    func clearCache() throws {
        try cache?.remove()
        state = .idle
    }

    func statusTitle() -> String {
        guard let snapshot = currentSnapshot else {
            return isLoading ? "..." : "0"
        }

        return "\(snapshot.availableCredits.count)"
    }

    func statusSymbolName(now: Date = Date()) -> String {
        if case .failed = state, currentSnapshot == nil {
            return "wifi.exclamationmark"
        }

        guard let nextExpiration = currentSnapshot?.nextExpiringCredit?.expiresAt else {
            return "arrow.triangle.2.circlepath.circle.fill"
        }

        let remaining = nextExpiration.timeIntervalSince(now)
        if remaining <= 24 * 60 * 60 {
            return "exclamationmark.triangle.fill"
        }

        return "checkmark.circle.fill"
    }

    func tooltip(now: Date = Date()) -> String {
        switch state {
        case .idle:
            return "Codex reset credits\nNo data loaded"
        case let .loading(cachedSnapshot):
            return tooltip(prefix: "Refreshing reset credits", snapshot: cachedSnapshot, now: now)
        case let .loaded(snapshot):
            return tooltip(prefix: "Codex reset credits", snapshot: snapshot, now: now)
        case let .failed(message, cachedSnapshot):
            return tooltip(prefix: "Refresh failed: \(message)", snapshot: cachedSnapshot, now: now)
        }
    }

    private func refreshNow() async {
        let cachedSnapshot = currentSnapshot ?? (try? cache?.load())
        state = .loading(cachedSnapshot)

        do {
            let snapshot = try await client.fetchCredits()
            try? cache?.save(snapshot)
            state = .loaded(snapshot)
        } catch {
            let fallbackSnapshot = currentSnapshot ?? (try? cache?.load())
            state = .failed(Self.failureMessage(from: error), fallbackSnapshot)
        }
    }

    private func tooltip(prefix: String, snapshot: CreditsSnapshot?, now: Date) -> String {
        guard let snapshot else {
            return prefix
        }

        var lines = [
            prefix,
            "\(snapshot.availableCredits.count) reset credits available",
            "Last refresh: \(dateFormatter.string(from: snapshot.fetchedAt))"
        ]

        if let nextExpiration = snapshot.nextExpiringCredit?.expiresAt {
            lines.append("Next expiry: \(countdownFormatter.string(from: now, to: nextExpiration))")
            lines.append("Expires: \(dateFormatter.string(from: nextExpiration))")
        }

        return lines.joined(separator: "\n")
    }

    private static func failureMessage(from error: Error) -> String {
        let description = error.localizedDescription
        return description.isEmpty ? "Could not refresh reset credits." : description
    }
}
