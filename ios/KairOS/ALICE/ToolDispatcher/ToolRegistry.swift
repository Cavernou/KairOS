import Foundation

struct ToolDefinition: Identifiable {
    let id: String
    let requiresConfirmation: Bool
}

struct ToolRegistry {
    let tools: [ToolDefinition] = [
        ToolDefinition(id: "send_message", requiresConfirmation: true),
        ToolDefinition(id: "list_files", requiresConfirmation: false),
        ToolDefinition(id: "read_file", requiresConfirmation: false),
        ToolDefinition(id: "search_contacts", requiresConfirmation: false),
        ToolDefinition(id: "start_call", requiresConfirmation: true),
        ToolDefinition(id: "delete_file", requiresConfirmation: true)
    ]
}
