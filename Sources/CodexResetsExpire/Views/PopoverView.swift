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
                .frame(width: 276)
                .background(.regularMaterial)
        }
    }

    private func content(now: Date) -> some View {
        VStack(spacing: 0) {
            header

            Divider()

            summary(now: now)

            Divider()

            creditList(now: now)

            Divider()

            footer
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.white.opacity(0.12))
        }
    }

    private var header: some View {
        HStack(spacing: 7) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Codex resets")
                .font(.system(size: 12, weight: .semibold))

            Spacer()

            if store.isLoading {
                ProgressView()
                    .controlSize(.mini)
            } else {
                Text(lastUpdatedText)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func summary(now: Date) -> some View {
        let credits = store.currentSnapshot?.availableCredits ?? []
        let nextExpiration = store.currentSnapshot?.nextExpiringCredit?.expiresAt
        let summaryTone = nextExpiration.map { tone(for: $0, now: now) } ?? StatusPill.Tone.neutral

        return HStack(spacing: 8) {
            Text("\(credits.count)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(summaryTone == .neutral ? Color.primary : summaryTone.color)

            Text(credits.count == 1 ? "reset available" : "resets available")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            if let nextExpiration {
                StatusPill(
                    text: countdownFormatter.string(from: now, to: nextExpiration),
                    systemImage: "clock",
                    tone: summaryTone
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(summaryTone.color.opacity(0.055))
    }

    @ViewBuilder
    private func creditList(now: Date) -> some View {
        if let failure = failureText {
            Text(failure)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        let credits = listedCredits
        if credits.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                ForEach(Array(credits.enumerated()), id: \.element.id) { index, credit in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 34)
                    }

                    ResetCreditRowView(credit: credit, now: now)
                }
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: 7) {
            Image(systemName: "circle.dashed")
                .foregroundStyle(.secondary)
            Text("No reset credits")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button(action: actions.refresh) {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(store.isLoading)
            .help("Refresh")

            Button(action: actions.openCodex) {
                Image(systemName: "arrow.up.right")
            }
            .help("Open Codex")

            Spacer()

            Button(action: actions.hide) {
                Image(systemName: "eye.slash")
            }
            .help("Hide")

            Button(action: actions.quit) {
                Image(systemName: "power")
            }
            .help("Quit")
        }
        .buttonStyle(.borderless)
        .controlSize(.mini)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }

    private var lastUpdatedText: String {
        guard let snapshot = store.currentSnapshot else {
            return "not updated"
        }
        return DateFormatters.localDateString(for: snapshot.fetchedAt)
    }

    private var failureText: String? {
        if case let .failed(message, _) = store.state {
            return message
        }
        return nil
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

    private var listedCredits: [ResetCredit] {
        store.currentSnapshot?.availableCredits ?? []
    }
}
