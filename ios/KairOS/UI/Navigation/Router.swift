import Foundation

enum AppTab: CaseIterable {
    case messages
    case files
    case contacts
    case calling
    case nodes
    case apps
    case settings
    case blackbox

    var label: String {
        switch self {
        case .messages: "MESSAGES"
        case .files: "FILES"
        case .contacts: "CONTACTS"
        case .calling: "CALLING"
        case .nodes: "NODES"
        case .apps: "APPS"
        case .settings: "SETTINGS"
        case .blackbox: "BLACKBOX"
        }
    }
}
