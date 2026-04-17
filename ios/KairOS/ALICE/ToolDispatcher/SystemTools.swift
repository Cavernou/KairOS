import Foundation

struct SystemTools {
    func requiresConfirmation(for toolID: String) -> Bool {
        ToolRegistry().tools.first(where: { $0.id == toolID })?.requiresConfirmation ?? true
    }
}
