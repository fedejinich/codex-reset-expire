import Foundation

protocol ResetCreditsClientProtocol {
    func fetchCredits() async throws -> CreditsSnapshot
}

final class ResetCreditsClient: ResetCreditsClientProtocol {
    private static let defaultEndpoint = URL(string: "https://chatgpt.com/backend-api/wham/rate-limit-reset-credits")!

    private let tokenProvider: AuthTokenProviding
    private let endpoint: URL
    private let session: URLSession

    init(
        tokenProvider: AuthTokenProviding,
        endpoint: URL = ResetCreditsClient.defaultEndpoint,
        session: URLSession = .shared
    ) {
        self.tokenProvider = tokenProvider
        self.endpoint = endpoint
        self.session = session
    }

    func fetchCredits() async throws -> CreditsSnapshot {
        let token = try tokenProvider.loadToken()
        let request = Self.makeRequest(endpoint: endpoint, tokens: token)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ResetCreditsClientError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw ResetCreditsClientError.httpStatus(httpResponse.statusCode)
        }

        return try ResetCreditsDecoder.decode(data: data, fetchedAt: Date())
    }

    static func makeRequest(
        endpoint: URL = ResetCreditsClient.defaultEndpoint,
        tokens: CodexAuthToken
    ) -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(tokens.accountID, forHTTPHeaderField: "ChatGPT-Account-ID")
        request.setValue("codex-1", forHTTPHeaderField: "OpenAI-Beta")
        request.setValue("Codex Desktop", forHTTPHeaderField: "originator")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}

enum ResetCreditsClientError: LocalizedError, Equatable {
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Codex returned an invalid response"
        case let .httpStatus(status):
            return "Codex returned HTTP \(status)"
        }
    }
}

enum ResetCreditsDecoder {
    static func decode(data: Data, fetchedAt: Date) throws -> CreditsSnapshot {
        if let credits = try? JSONDecoder().decode([ResetCredit].self, from: data) {
            return CreditsSnapshot(credits: credits, fetchedAt: fetchedAt)
        }

        let dto = try JSONDecoder().decode(ResetCreditsResponseDTO.self, from: data)
        let credits = dto.credits
        let availableCount = dto.availableCount
        return CreditsSnapshot(credits: credits, availableCount: availableCount, fetchedAt: fetchedAt)
    }
}

private struct ResetCreditsResponseDTO: Decodable {
    let credits: [ResetCredit]
    let availableCount: Int?

    enum CodingKeys: String, CodingKey {
        case credits
        case resetCredits = "reset_credits"
        case resetCreditsCamel = "resetCredits"
        case items
        case data
        case availableCount = "available_count"
        case availableCountCamel = "availableCount"
        case availableCredits = "available_credits"
        case availableCreditsCamel = "availableCredits"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        credits = try container.decodeFirstPresentArray(
            forKeys: [.credits, .resetCredits, .resetCreditsCamel, .items, .data]
        ) ?? []
        availableCount = try container.decodeFirstPresentInt(
            forKeys: [.availableCount, .availableCountCamel, .availableCredits, .availableCreditsCamel]
        )
    }
}

extension CreditsSnapshot {
    static func decode(from data: Data, fetchedAt: Date = Date()) throws -> CreditsSnapshot {
        try ResetCreditsDecoder.decode(data: data, fetchedAt: fetchedAt)
    }
}

private extension KeyedDecodingContainer {
    func decodeFirstPresentArray<T: Decodable>(forKeys keys: [Key]) throws -> [T]? {
        for key in keys where contains(key) {
            if let value = try decodeIfPresent([T].self, forKey: key) {
                return value
            }
        }

        return nil
    }

    func decodeFirstPresentInt(forKeys keys: [Key]) throws -> Int? {
        for key in keys where contains(key) {
            if let value = try? decodeIfPresent(Int.self, forKey: key) {
                return value
            }

            if let value = try? decodeIfPresent(Double.self, forKey: key) {
                return Int(value)
            }

            if let value = try? decodeIfPresent(String.self, forKey: key),
               let intValue = Int(value) {
                return intValue
            }
        }

        return nil
    }
}
