import SwiftUI

struct ResetCreditRowView: View {
    var credit: ResetCredit
    var now: Date

    private let countdownFormatter = CountdownFormatter()

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(tone.color.opacity(0.14))
                    .frame(width: 28, height: 28)
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tone.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(credit.title.isEmpty ? "Reset credit" : credit.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(detailText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            StatusPill(
                text: countdownFormatter.string(from: now, to: credit.expiresAt),
                systemImage: pillIconName,
                tone: tone
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.quaternary.opacity(0.48))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(tone.color.opacity(0.14))
                }
        }
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
            return "checkmark.seal.fill"
        }

        return remaining <= 86_400 ? "exclamationmark.triangle.fill" : "checkmark.seal.fill"
    }

    private var pillIconName: String {
        remaining <= 86_400 ? "timer" : "clock"
    }

    private var detailText: String {
        let localDate = DateFormatters.localDateString(for: credit.expiresAt)
        let type = credit.resetType
            .replacingOccurrences(of: "_", with: " ")
            .capitalized

        if credit.isAvailable {
            return type.isEmpty ? "Expires \(localDate)" : "\(type) · Expires \(localDate)"
        }

        let status = credit.status
            .replacingOccurrences(of: "_", with: " ")
            .capitalized

        return [status, type, localDate]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}
