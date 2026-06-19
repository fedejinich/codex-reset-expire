import Foundation

public final class CreditsCache<Snapshot: Codable> {
    public let fileURL: URL

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        fileURL: URL,
        fileManager: FileManager = .default,
        encoder: JSONEncoder = CreditsCache.defaultEncoder(),
        decoder: JSONDecoder = CreditsCache.defaultDecoder()
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.encoder = encoder
        self.decoder = decoder
    }

    public convenience init(
        applicationName: String = "CodexResetsExpire",
        fileManager: FileManager = .default
    ) throws {
        let fileURL = try Self.defaultFileURL(
            applicationName: applicationName,
            fileManager: fileManager
        )

        self.init(fileURL: fileURL, fileManager: fileManager)
    }

    public func load() throws -> Snapshot? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(Snapshot.self, from: data)
    }

    public func save(_ snapshot: Snapshot) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func remove() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        try fileManager.removeItem(at: fileURL)
    }

    public static func defaultFileURL(
        applicationName: String = "CodexResetsExpire",
        fileManager: FileManager = .default
    ) throws -> URL {
        let directoryURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent(applicationName, isDirectory: true)

        return directoryURL.appendingPathComponent("credits-snapshot.json")
    }

    public static func defaultEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    public static func defaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
