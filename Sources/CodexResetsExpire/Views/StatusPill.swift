import SwiftUI

struct StatusPill: View {
    enum Tone {
        case calm
        case warning
        case danger
        case neutral

        var color: Color {
            switch self {
            case .calm:
                return .green
            case .warning:
                return .orange
            case .danger:
                return .red
            case .neutral:
                return .secondary
            }
        }
    }

    var text: String
    var systemImage: String
    var tone: Tone

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.system(size: 8, weight: .bold))

            Text(text)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .monospacedDigit()
        }
        .foregroundStyle(tone.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .fixedSize(horizontal: true, vertical: false)
        .background {
            Capsule()
                .fill(tone.color.opacity(0.10))
                .overlay {
                    Capsule()
                        .strokeBorder(tone.color.opacity(0.18), lineWidth: 1)
                }
        }
    }
}
