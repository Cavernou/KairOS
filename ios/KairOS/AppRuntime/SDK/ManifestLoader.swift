import Foundation

struct AppManifest: Codable, Identifiable {
    let id: String
    let name: String
    let version: String
    let entryType: String
    let permissions: [String]
    let aiSummary: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case version
        case entryType = "entry_type"
        case permissions
        case aiSummary = "ai_summary"
    }
}

enum ManifestLoader {
    static func load(url: URL) throws -> AppManifest {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(AppManifest.self, from: data)
    }
}
