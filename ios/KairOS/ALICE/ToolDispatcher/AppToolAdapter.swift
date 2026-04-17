import Foundation

struct AppToolAdapter {
    func execute(toolID: String, payload: [String: String]) async throws -> String {
        "Executed \(toolID) with payload keys: \(payload.keys.sorted().joined(separator: ","))"
    }
}
