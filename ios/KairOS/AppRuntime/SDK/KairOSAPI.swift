import Foundation

@MainActor
protocol KairOSAPI {
    func readFile(named: String) -> Data?
    func writeFile(named: String, data: Data) throws
    func listFiles() -> [String]
    func sendMessage(to kairNumber: String, text: String, attachments: [URL]?) async throws
    func queryALICE(prompt: String) async -> String
    func publish(event: String, payload: [String: Any])
    func subscribe(to event: String, handler: @escaping ([String: Any]) -> Void)
}
