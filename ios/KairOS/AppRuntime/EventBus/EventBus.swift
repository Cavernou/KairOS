import Foundation

@MainActor
final class EventBus {
    static let shared = EventBus()
    
    typealias Handler = ([String: Any]) -> Void
    private var handlers: [String: [UUID: Handler]] = [:]

    func publish(event: String, payload: [String: Any]) {
        handlers[event]?.values.forEach { $0(payload) }
    }

    @discardableResult
    func subscribe(to event: String, handler: @escaping Handler) -> UUID {
        let id = UUID()
        handlers[event, default: [:]][id] = handler
        return id
    }
    
    func unsubscribe(id: UUID, from event: String) {
        handlers[event]?.removeValue(forKey: id)
    }
}
