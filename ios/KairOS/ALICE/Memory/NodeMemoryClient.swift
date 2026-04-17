import Foundation

struct NodeMemoryClient {
    let nodeClient: NodeClient

    func sync(entry: MemoryEntry) async throws {
        try await nodeClient.syncMemory(entry)
    }
}
