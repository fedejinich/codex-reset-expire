import Foundation

enum DateParsing {
    private static let fractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let standardFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parseISO8601(_ value: String) throws -> Date {
        if let date = fractionalFormatter.date(from: value) ?? standardFormatter.date(from: value) {
            return date
        }
        throw DateParsingError.invalidDate(value)
    }

    static func iso8601String(from date: Date) -> String {
        fractionalFormatter.string(from: date)
    }
}

enum DateParsingError: LocalizedError, Equatable {
    case invalidDate(String)

    var errorDescription: String? {
        switch self {
        case let .invalidDate(value):
            return "Invalid ISO-8601 date: \(value)"
        }
    }
}

public struct LocalDateFormatter {
    private let locale: Locale
    private let timeZone: TimeZone
    private let calendar: Calendar

    public init(
        locale: Locale = Locale(identifier: "es_AR"),
        timeZone: TimeZone = .autoupdatingCurrent,
        calendar: Calendar = .current
    ) {
        self.locale = locale
        self.timeZone = timeZone
        self.calendar = calendar
    }

    public func string(from date: Date) -> String {
        DateFormatters.localDateString(
            for: date,
            locale: locale,
            timeZone: timeZone,
            calendar: calendar
        )
    }
}

public enum DateFormatters {
    public static func localDateString(
        for date: Date,
        locale: Locale = Locale(identifier: "es_AR"),
        timeZone: TimeZone = .autoupdatingCurrent,
        calendar: Calendar = .current
    ) -> String {
        let formatter = DateFormatter()
        var configuredCalendar = calendar
        configuredCalendar.timeZone = timeZone

        formatter.calendar = configuredCalendar
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return formatter.string(from: date)
    }
}
