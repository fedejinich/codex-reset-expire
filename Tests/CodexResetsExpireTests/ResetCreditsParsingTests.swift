import Foundation
import XCTest
@testable import CodexResetsExpire

final class ResetCreditsParsingTests: XCTestCase {
    func testDecodesCreditsAndSortsAvailableByExpiration() throws {
        let json = """
        {
          "credits": [
            {
              "id": "later",
              "reset_type": "codex_rate_limits",
              "status": "available",
              "granted_at": "2026-06-18T00:33:28.145483Z",
              "expires_at": "2026-07-18T00:33:28.145483Z",
              "title": "One free rate limit reset"
            },
            {
              "id": "used",
              "reset_type": "codex_rate_limits",
              "status": "redeemed",
              "granted_at": "2026-06-12T01:42:15.242456Z",
              "expires_at": "2026-07-12T01:42:15.242456Z",
              "title": "One free rate limit reset"
            },
            {
              "id": "soon",
              "reset_type": "codex_rate_limits",
              "status": "available",
              "granted_at": "2026-06-12T01:42:15.242456Z",
              "expires_at": "2026-07-12T01:42:15.242456Z",
              "title": "One free rate limit reset"
            }
          ],
          "available_count": 2,
          "total_earned_count": 0
        }
        """
        let fetchedAt = Date(timeIntervalSince1970: 1_781_879_200)

        let snapshot = try ResetCreditsDecoder.decode(data: Data(json.utf8), fetchedAt: fetchedAt)

        XCTAssertEqual(snapshot.availableCount, 2)
        XCTAssertEqual(snapshot.credits.count, 3)
        XCTAssertEqual(snapshot.availableCredits.map(\.id), ["soon", "later"])
        XCTAssertEqual(snapshot.nextExpiringCredit?.id, "soon")
        XCTAssertEqual(snapshot.fetchedAt, fetchedAt)
    }

    func testDecodesDatesWithoutFractionalSeconds() throws {
        let json = """
        {
          "credits": [
            {
              "id": "plain-date",
              "reset_type": "codex_rate_limits",
              "status": "available",
              "granted_at": "2026-06-18T00:33:28Z",
              "expires_at": "2026-07-18T00:33:28Z",
              "title": "One free rate limit reset"
            }
          ]
        }
        """

        let snapshot = try ResetCreditsDecoder.decode(data: Data(json.utf8), fetchedAt: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(snapshot.availableCount, 1)
        XCTAssertEqual(snapshot.availableCredits.first?.id, "plain-date")
    }

    func testParsesCodexAuthTokensFromAuthFile() throws {
        let authFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let json = """
        {
          "tokens": {
            "access_token": "test-access-token",
            "account_id": "test-account-id"
          }
        }
        """
        try json.write(to: authFileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: authFileURL) }

        let token = try FileAuthTokenProvider(authFileURL: authFileURL).loadToken()

        XCTAssertEqual(token.accessToken, "test-access-token")
        XCTAssertEqual(token.accountID, "test-account-id")
    }

    func testBuildsResetCreditsRequestWithCodexHeaders() throws {
        let endpoint = try XCTUnwrap(URL(string: "https://chatgpt.com/backend-api/wham/rate-limit-reset-credits"))
        let token = CodexAuthToken(accessToken: "test-access-token", accountID: "test-account-id")

        let request = ResetCreditsClient.makeRequest(endpoint: endpoint, tokens: token)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url, endpoint)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-access-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "ChatGPT-Account-ID"), "test-account-id")
        XCTAssertEqual(request.value(forHTTPHeaderField: "OpenAI-Beta"), "codex-1")
        XCTAssertEqual(request.value(forHTTPHeaderField: "originator"), "Codex Desktop")
    }
}
