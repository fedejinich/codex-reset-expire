import Foundation

public struct CountdownFormatter {
    public init() {}

    public func compactString(from now: Date = Date(), to expiration: Date) -> String {
        let seconds = Int(expiration.timeIntervalSince(now).rounded(.down))
        guard seconds > 0 else {
            return "vencido"
        }

        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = max(1, (seconds % 3_600) / 60)

        if days > 0 {
            return "\(days)d \(hours)h"
        }

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }

    public func sentence(from now: Date = Date(), to expiration: Date) -> String {
        let compact = compactString(from: now, to: expiration)
        return compact == "vencido" ? compact : "vence en \(compact)"
    }

    public func string(from now: Date = Date(), to expiration: Date) -> String {
        compactString(from: now, to: expiration)
    }
}
