import SwiftUI

struct ResetCreditRowView: View {
    var credit: ResetCredit
    var now: Date

    private let countdownFormatter = CountdownFormatter()

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tone.color)
                .frame(width: 17, height: 17)

            VStack(alignment: .leading, spacing: 1) {
                Text(credit.title.isEmpty ? "Reset credit" : credit.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(detailText)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            StatusPill(
                text: countdownFormatter.string(from: now, to: credit.expiresAt),
                systemImage: "clock",
                tone: tone
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
    }

    private var remaining: TimeInterval {
        credit.expiresAt.timeIntervalSince(now)
    }

    private var tone: StatusPill.Tone {
        if !credit.isAvailable {
            return .neutral
        }
        if remaining <= 86_400 {
            return .danger
        }
        if remaining <= 604_800 {
            return .warning
        }
        return .calm
    }

    private var iconName: String {
        if !credit.isAvailable {
            return "checkmark.circle.fill"
        }

        return remaining <= 86_400 ? "exclamationmark.circle.fill" : "arrow.clockwise.circle.fill"
    }

    private var detailText: String {
        let type = credit.resetType
            .replacingOccurrences(of: "_", with: " ")
            .capitalized

        if credit.isAvailable {
            return type.isEmpty ? "Available" : type
        }

        let status = credit.status
            .replacingOccurrences(of: "_", with: " ")
            .capitalized

        return [status, type]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}
