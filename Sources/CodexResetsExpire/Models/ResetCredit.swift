import Foundation

struct ResetCredit: Codable, Equatable, Identifiable {
    let id: String
    let resetType: String
    let status: String
    let grantedAt: Date
    let expiresAt: Date
    let title: String
    let availableCredits: Int

    var isAvailable: Bool {
        status == "available" && availableCredits > 0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case resetType = "reset_type"
        case resetTypeCamel = "resetType"
        case status
        case grantedAt = "granted_at"
        case grantedAtCamel = "grantedAt"
        case expiresAt = "expires_at"
        case expiresAtCamel = "expiresAt"
        case expirationTime = "expiration_time"
        case expirationTimeCamel = "expirationTime"
        case expires
        case title
        case availableCredits = "available_credits"
        case availableCreditsCamel = "availableCredits"
        case credits
        case count
        case value
        case amount
        case quantity
    }

    init(
        id: String,
        resetType: String = "rate_limit_reset",
        status: String = "available",
        grantedAt: Date? = nil,
        expiresAt: Date,
        title: String = "Rate limit reset",
        availableCredits: Int = 1
    ) {
        self.id = id
        self.resetType = resetType
        self.status = status
        self.grantedAt = grantedAt ?? expiresAt
        self.expiresAt = expiresAt
        self.title = title
        self.availableCredits = availableCredits
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        expiresAt = try Self.decodeDate(
            from: container,
            keys: [.expiresAt, .expiresAtCamel, .expirationTime, .expirationTimeCamel, .expires]
        )
        availableCredits = try Self.decodeInt(
            from: container,
            keys: [.availableCredits, .availableCreditsCamel, .credits, .count, .value, .amount, .quantity]
        ) ?? 1

        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? "\(Int(expiresAt.timeIntervalSince1970))-\(availableCredits)"
        resetType = try container.decodeIfPresent(String.self, forKey: .resetType)
            ?? container.decodeIfPresent(String.self, forKey: .resetTypeCamel)
            ?? "rate_limit_reset"
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "available"
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Rate limit reset"
        grantedAt = try Self.decodeOptionalDate(from: container, keys: [.grantedAt, .grantedAtCamel]) ?? expiresAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(resetType, forKey: .resetType)
        try container.encode(status, forKey: .status)
        try container.encode(DateParsing.iso8601String(from: grantedAt), forKey: .grantedAt)
        try container.encode(DateParsing.iso8601String(from: expiresAt), forKey: .expiresAt)
        try container.encode(title, forKey: .title)
        try container.encode(availableCredits, forKey: .credits)
    }

    private static func decodeDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) throws -> Date {
        if let date = try decodeOptionalDate(from: container, keys: keys) {
            return date
        }

        throw DecodingError.keyNotFound(
            CodingKeys.expiresAt,
            DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Missing reset credit expiration date"
            )
        )
    }

    private static func decodeOptionalDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) throws -> Date? {
        for key in keys {
            if let string = try? container.decode(String.self, forKey: key) {
                return try DateParsing.parseISO8601(string)
            }

            if let seconds = try? container.decode(Double.self, forKey: key) {
                return Date(timeIntervalSince1970: seconds)
            }
        }

        return nil
    }

    private static func decodeInt(
        from container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) throws -> Int? {
        for key in keys {
            if let intValue = try? container.decode(Int.self, forKey: key) {
                return intValue
            }

            if let doubleValue = try? container.decode(Double.self, forKey: key) {
                return Int(doubleValue)
            }

            if let stringValue = try? container.decode(String.self, forKey: key),
               let intValue = Int(stringValue) {
                return intValue
            }
        }

        return nil
    }
}

enum ResetCreditDateParser {
    static func date(from value: String) -> Date? {
        try? DateParsing.parseISO8601(value)
    }
}
