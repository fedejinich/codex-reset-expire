import Foundation
import XCTest
@testable import CodexResetsExpire

final class CountdownFormatterTests: XCTestCase {
    private let formatter = CountdownFormatter()
    private let now = Date(timeIntervalSince1970: 1_781_879_200)

    func testFormatsDaysAndHours() {
        let expiration = now.addingTimeInterval((2 * 86_400) + (3 * 3_600) + (20 * 60))

        XCTAssertEqual(formatter.compactString(from: now, to: expiration), "2d 3h")
        XCTAssertEqual(formatter.sentence(from: now, to: expiration), "vence en 2d 3h")
    }

    func testFormatsHoursAndMinutes() {
        let expiration = now.addingTimeInterval((5 * 3_600) + (42 * 60))

        XCTAssertEqual(formatter.compactString(from: now, to: expiration), "5h 42m")
    }

    func testFormatsShortDurationsAsAtLeastOneMinute() {
        let expiration = now.addingTimeInterval(20)

        XCTAssertEqual(formatter.compactString(from: now, to: expiration), "1m")
    }

    func testFormatsExpired() {
        let expiration = now.addingTimeInterval(-10)

        XCTAssertEqual(formatter.compactString(from: now, to: expiration), "vencido")
        XCTAssertEqual(formatter.sentence(from: now, to: expiration), "vencido")
    }
}
