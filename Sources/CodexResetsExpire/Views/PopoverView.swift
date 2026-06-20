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

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private let countdownFormatter = CountdownFormatter()

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            content(now: context.date)
                .frame(width: 304, height: 206)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func content(now: Date) -> some View {
        VStack(spacing: 0) {
            header

            summary(now: now)

            Divider()
                .opacity(0.45)

            creditList(now: now)

            Spacer(minLength: 0)

            Divider()
                .opacity(0.45)

            footer
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
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private func summary(now: Date) -> some View {
        let credits = store.currentSnapshot?.availableCredits ?? []
        let nextExpiration = store.currentSnapshot?.nextExpiringCredit?.expiresAt
        let summaryTone = nextExpiration.map { tone(for: $0, now: now) } ?? StatusPill.Tone.neutral

        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(credits.count)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(summaryTone == .neutral ? Color.primary : summaryTone.color)

            Text(credits.count == 1 ? "reset" : "resets")
                .font(.system(size: 12, weight: .semibold))
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
        .padding(.horizontal, 12)
        .padding(.bottom, 9)
        .background(summaryTone.color.opacity(0.055))
    }

    @ViewBuilder
    private func creditList(now: Date) -> some View {
        if let failure = failureText {
            Text(failure)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if listedCredits.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                ForEach(Array(listedCredits.prefix(3).enumerated()), id: \.element.id) { index, credit in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 34)
                            .opacity(0.35)
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
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }

    private var footer: some View {
        HStack(spacing: 11) {
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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var lastUpdatedText: String {
        guard let snapshot = store.currentSnapshot else {
            return "not updated"
        }
        return Self.timeFormatter.string(from: snapshot.fetchedAt)
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
