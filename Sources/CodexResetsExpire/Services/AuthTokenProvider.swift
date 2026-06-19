import Foundation

struct CodexAuthToken: Equatable {
    let accessToken: String
    let accountID: String
}

typealias CodexAuthTokens = CodexAuthToken
typealias AuthTokenProvider = FileAuthTokenProvider

protocol AuthTokenProviding {
    func loadToken() throws -> CodexAuthToken
}

extension AuthTokenProviding {
    func loadTokens() throws -> CodexAuthToken {
        try loadToken()
    }
}

struct FileAuthTokenProvider: AuthTokenProviding {
    var authFileURL: URL

    init(authFileURL: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex/auth.json")) {
        self.authFileURL = authFileURL
    }

    func loadToken() throws -> CodexAuthToken {
        let data = try Data(contentsOf: authFileURL)
        let authFile = try JSONDecoder().decode(AuthFile.self, from: data)

        guard !authFile.tokens.accessToken.isEmpty else {
            throw AuthTokenProviderError.missingAccessToken
        }

        guard !authFile.tokens.accountID.isEmpty else {
            throw AuthTokenProviderError.missingAccountID
        }

        return CodexAuthToken(accessToken: authFile.tokens.accessToken, accountID: authFile.tokens.accountID)
    }
}

enum AuthTokenProviderError: LocalizedError, Equatable {
    case missingAccessToken
    case missingAccountID

    var errorDescription: String? {
        switch self {
        case .missingAccessToken:
            return "No access token found in ~/.codex/auth.json"
        case .missingAccountID:
            return "No account id found in ~/.codex/auth.json"
        }
    }
}

private struct AuthFile: Decodable {
    let tokens: Tokens
}

private struct Tokens: Decodable {
    let accessToken: String
    let accountID: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case accountID = "account_id"
    }
}
