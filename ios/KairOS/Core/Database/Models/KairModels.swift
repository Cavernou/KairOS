import Foundation

struct DeviceIdentity: Codable, Equatable {
    let deviceID: UUID
    let kairNumber: String
    let status: String
    let activationTimestamp: Date?
}

struct ContactRecord: Codable, Identifiable, Equatable {
    let id: String
    let displayName: String
    let realPhone: String?
    let notes: String?
    let trustStatus: String
    let lastInteraction: Date?
    let avatarASCII: String?
}

struct MessageRecord: Codable, Identifiable, Equatable {
    let id: String
    let senderKNumber: String
    let receiverKNumber: String
    let text: String?
    let timestamp: Date
    let status: String
    let hasAttachments: Bool
    let encryptedPayload: Data?
}

struct FileRecord: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let type: String
    let size: Int
    let hash: String
    let localPath: String
    let encrypted: Bool
    let createdAt: Date
}

struct AIMemoryRecord: Codable, Identifiable, Equatable {
    let id: String
    let memoryType: String
    let targetID: String?
    let content: String
    let importance: Double
    let createdAt: Date
    let syncedToNode: Bool
}

struct BlackboxSnapshotRecord: Codable, Identifiable, Equatable {
    let id: String
    let filename: String
    let createdAt: Date
    let size: Int
    let checksum: String
    let location: String?
}

struct NodeStatus: Equatable {
    var isReachable: Bool
    var tailnet: String
    var lastSync: Date?
}

struct MessagePacket: Codable {
    let id: String
    let type: String
    let senderKair: String
    let receiverKair: String
    let timestamp: Int64
    let encryptedPayload: Data
    let nodeRoute: [String]
    let hasAttachments: Bool
}
