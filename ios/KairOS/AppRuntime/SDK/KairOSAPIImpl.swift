import Foundation

@MainActor
class KairOSAPIImpl: NSObject, KairOSAPI, ObservableObject {
    private let fileManager = FileManager.default
    private let eventBus = EventBus.shared
    private let nodeClient: NodeClient
    private let aliceOrchestrator: ALICEOrchestrator
    
    init(nodeClient: NodeClient, aliceOrchestrator: ALICEOrchestrator) {
        self.nodeClient = nodeClient
        self.aliceOrchestrator = aliceOrchestrator
    }
    
    func readFile(named: String) -> Data? {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let fileURL = documentsURL.appendingPathComponent("Apps").appendingPathComponent(named)
        return try? Data(contentsOf: fileURL)
    }
    
    func writeFile(named: String, data: Data) throws {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "KairOSAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory unavailable"])
        }
        let appsDirectory = documentsURL.appendingPathComponent("Apps")
        try fileManager.createDirectory(at: appsDirectory, withIntermediateDirectories: true)
        let fileURL = appsDirectory.appendingPathComponent(named)
        try data.write(to: fileURL)
    }
    
    func listFiles() -> [String] {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        let appsDirectory = documentsURL.appendingPathComponent("Apps")
        guard let files = try? fileManager.contentsOfDirectory(atPath: appsDirectory.path) else {
            return []
        }
        return files
    }
    
    func sendMessage(to kairNumber: String, text: String, attachments: [URL]?) async throws {
        // This would integrate with the main app's messaging system
        // For now, publish event for the main app to handle
        publish(event: "app.send_message", payload: [
            "to": kairNumber,
            "text": text,
            "attachments": attachments?.map { $0.absoluteString } ?? []
        ])
    }
    
    func queryALICE(prompt: String) async -> String {
        return await aliceOrchestrator.handle(prompt: prompt)
    }
    
    func publish(event: String, payload: [String: Any]) {
        eventBus.publish(event: event, payload: payload)
    }
    
    func subscribe(to event: String, handler: @escaping ([String: Any]) -> Void) {
        eventBus.subscribe(to: event, handler: handler)
    }
}
