import Foundation

struct CreditsSnapshot: Codable, Equatable {
    let credits: [ResetCredit]
    let availableCount: Int
    let fetchedAt: Date

    var availableCredits: [ResetCredit] {
        credits
            .filter(\.isAvailable)
            .sorted { $0.expiresAt < $1.expiresAt }
    }

    var nextExpiringCredit: ResetCredit? {
        availableCredits.first
    }

    var totalAvailableCredits: Int {
        availableCount
    }

    static let empty = CreditsSnapshot(credits: [], availableCount: 0, fetchedAt: Date(timeIntervalSince1970: 0))

    init(credits: [ResetCredit], availableCount: Int? = nil, fetchedAt: Date) {
        self.credits = credits.sorted {
            if $0.expiresAt == $1.expiresAt {
                return $0.id < $1.id
            }

            return $0.expiresAt < $1.expiresAt
        }
        self.availableCount = availableCount ?? credits.reduce(0) { total, credit in
            credit.isAvailable ? total + credit.availableCredits : total
        }
        self.fetchedAt = fetchedAt
    }
}
