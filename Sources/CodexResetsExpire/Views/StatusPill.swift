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
        Label(text, systemImage: systemImage)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(tone.color)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(tone.color.opacity(0.14))
                    .overlay {
                        Capsule()
                            .strokeBorder(tone.color.opacity(0.24), lineWidth: 1)
                    }
            }
    }
}
