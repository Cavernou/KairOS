import Combine
import Foundation

@MainActor
final class ALICEOrchestrator: ObservableObject {
    private let memory = ShortTermMemory()
    private let engine = InferenceEngine()
    private let systemTools = SystemTools()

    func handle(prompt: String) async -> String {
        memory.append(prompt)
        return await engine.respond(to: prompt)
    }

    func shouldConfirm(toolID: String) -> Bool {
        systemTools.requiresConfirmation(for: toolID)
    }
}
