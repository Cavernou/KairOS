import Foundation

enum EventType: String {
    case messageReceived = "message.received"
    case contactAdded = "contact.added"
    case nodeStatusChanged = "node.status.changed"
    case callIncoming = "call.incoming"
}
