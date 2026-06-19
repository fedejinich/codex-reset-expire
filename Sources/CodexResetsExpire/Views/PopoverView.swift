import SwiftUI

struct PopoverActions {
    var refresh: () -> Void
    var openCodex: () -> Void
    var hide: () -> Void
    var quit: () -> Void
}

struct PopoverView: View {
    @ObservedObject var store: ResetCreditsStore
    var actions: PopoverActions

    private let countdownFormatter = CountdownFormatter()

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            content(now: context.date)
                .frame(width: 372)
                .background(.regularMaterial)
        }
    }

    private func content(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            hero(now: now)

            creditList(now: now)

            footer
        }
        .padding(18)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 1) {
                Text("Codex resets")
                    .font(.system(size: 15, weight: .semibold))
                Text(lastUpdatedText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if store.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private func hero(now: Date) -> some View {
        let snapshot = store.currentSnapshot
        let credits = snapshot?.availableCredits ?? []
        let nextExpiration = snapshot?.nextExpiringCredit?.expiresAt
        let heroTone = nextExpiration.map { tone(for: $0, now: now) } ?? StatusPill.Tone.neutral

        return HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(credits.count)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(heroTone == .neutral ? Color.primary : heroTone.color)
                Text(credits.count == 1 ? "available reset credit" : "available reset credits")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let nextExpiration {
                StatusPill(
                    text: "expires in \(countdownFormatter.string(from: now, to: nextExpiration))",
                    systemImage: "timer",
                    tone: tone(for: nextExpiration, now: now)
                )
                .padding(.bottom, 8)
            } else {
                StatusPill(text: "no resets", systemImage: "minus.circle", tone: .neutral)
                    .padding(.bottom, 8)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(heroAccent.opacity(0.11))
                        .frame(height: 58)
                        .blur(radius: 12)
                        .clipped()
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(heroAccent.opacity(0.18))
                }
        }
    }

    @ViewBuilder
    private func creditList(now: Date) -> some View {
        if let failure = failureText {
            Text(failure)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.red.opacity(0.09))
                }
        }

        let credits = sortedCredits
        if credits.isEmpty {
            emptyState
        } else {
            VStack(spacing: 8) {
                ForEach(credits) { credit in
                    ResetCreditRowView(credit: credit, now: now)
                }
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "circle.dashed")
                .foregroundStyle(.secondary)
            Text("No reset credits available")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.5))
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button(action: actions.refresh) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(store.isLoading)

            Button(action: actions.openCodex) {
                Label("Open", systemImage: "arrow.up.right")
            }
            .buttonStyle(.bordered)

            Spacer()

            Button(action: actions.hide) {
                Image(systemName: "eye.slash")
            }
            .buttonStyle(.borderless)
            .help("Hide")

            Button(action: actions.quit) {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit")
        }
        .controlSize(.small)
    }

    private var lastUpdatedText: String {
        guard let snapshot = store.currentSnapshot else {
            return store.isLoading ? "refreshing" : "not refreshed yet"
        }
        return "updated \(DateFormatters.localDateString(for: snapshot.fetchedAt))"
    }

    private var failureText: String? {
        if case let .failed(message, _) = store.state {
            return message
        }
        return nil
    }

    private var heroAccent: Color {
        guard let expiration = store.currentSnapshot?.nextExpiringCredit?.expiresAt else {
            return .secondary
        }
        return tone(for: expiration, now: Date()).color
    }

    private func tone(for expiration: Date, now: Date) -> StatusPill.Tone {
        let remaining = expiration.timeIntervalSince(now)
        if remaining <= 86_400 {
            return .danger
        }
        if remaining <= 604_800 {
            return .warning
        }
        return .calm
    }

    private var sortedCredits: [ResetCredit] {
        (store.currentSnapshot?.credits ?? [])
            .sorted { lhs, rhs in
                if lhs.isAvailable != rhs.isAvailable {
                    return lhs.isAvailable && !rhs.isAvailable
                }

                return lhs.expiresAt < rhs.expiresAt
            }
    }
}
