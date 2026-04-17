import Combine
import Foundation

@MainActor
final class ShortTermMemory: ObservableObject {
    @Published private(set) var exchanges: [String] = []

    func append(_ exchange: String) {
        exchanges.append(exchange)
        if exchanges.count > 10 {
            exchanges.removeFirst(exchanges.count - 10)
        }
    }
}
