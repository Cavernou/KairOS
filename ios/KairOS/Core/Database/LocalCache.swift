import Combine
import Foundation

@MainActor
final class LocalCache: ObservableObject {
    static let schemaSQL = """
    CREATE TABLE IF NOT EXISTS devices (
        device_id TEXT PRIMARY KEY,
        kair_number TEXT UNIQUE NOT NULL,
        public_key BLOB NOT NULL,
        status TEXT NOT NULL CHECK(status IN ('pending','active','revoked')),
        activated_by_node TEXT,
        activation_timestamp INTEGER,
        last_seen INTEGER
    );

    CREATE TABLE IF NOT EXISTS contacts (
        knumber TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        real_phone TEXT,
        notes TEXT,
        trust_status TEXT NOT NULL CHECK(trust_status IN ('unknown','pending','trusted','blocked')),
        last_interaction INTEGER,
        avatar_ascii TEXT
    );

    CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        sender_knumber TEXT NOT NULL,
        receiver_knumber TEXT NOT NULL,
        text TEXT,
        timestamp INTEGER NOT NULL,
        status TEXT NOT NULL CHECK(status IN ('queued','sent','delivered','failed')),
        has_attachments INTEGER DEFAULT 0,
        encrypted_payload BLOB
    );

    CREATE TABLE IF NOT EXISTS files (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('image','audio','video','binary','unknown')),
        size INTEGER NOT NULL,
        hash TEXT NOT NULL,
        local_path TEXT NOT NULL,
        encrypted INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS ai_memory (
        id TEXT PRIMARY KEY,
        memory_type TEXT NOT NULL,
        target_id TEXT,
        content TEXT NOT NULL,
        importance REAL DEFAULT 0.5,
        created_at INTEGER NOT NULL,
        synced_to_node INTEGER DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS blackbox_snapshots (
        id TEXT PRIMARY KEY,
        filename TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        size INTEGER NOT NULL,
        checksum TEXT NOT NULL,
        location TEXT
    );
    """

    @Published private(set) var messages: [MessageRecord] = []
    @Published private(set) var contacts: [ContactRecord] = []
    @Published private(set) var files: [FileRecord] = []
    @Published private(set) var memory: [AIMemoryRecord] = []
    @Published private(set) var snapshots: [BlackboxSnapshotRecord] = []

    func seedPreviewData() {
        guard messages.isEmpty, contacts.isEmpty else { return }

        contacts = [
            ContactRecord(id: "K-1000-0001", displayName: "Home Node", realPhone: nil, notes: "Trusted authority", trustStatus: "trusted", lastInteraction: .now, avatarASCII: "[NODE]"),
            ContactRecord(id: "K-2000-0002", displayName: "Field Contact", realPhone: nil, notes: "Pending sync", trustStatus: "pending", lastInteraction: .now.addingTimeInterval(-3200), avatarASCII: "<:>")
        ]

        messages = [
            MessageRecord(id: UUID().uuidString, senderKNumber: "K-1000-0001", receiverKNumber: "K-2000-0002", text: "QUEUE LINK STANDBY", timestamp: .now.addingTimeInterval(-400), status: "queued", hasAttachments: false, encryptedPayload: nil),
            MessageRecord(id: UUID().uuidString, senderKNumber: "K-2000-0002", receiverKNumber: "K-1000-0001", text: "ACK", timestamp: .now.addingTimeInterval(-120), status: "delivered", hasAttachments: false, encryptedPayload: nil)
        ]
    }

    func append(message: MessageRecord) {
        messages.insert(message, at: 0)
    }

    func record(snapshot: BlackboxSnapshotRecord) {
        snapshots.insert(snapshot, at: 0)
    }

    func replaceAll(from snapshot: CacheSnapshot) {
        contacts = snapshot.contacts
        messages = snapshot.messages
        files = snapshot.files
        memory = snapshot.memory
    }

    func snapshot() -> CacheSnapshot {
        CacheSnapshot(contacts: contacts, messages: messages, files: files, memory: memory)
    }
}

struct CacheSnapshot: Codable {
    let contacts: [ContactRecord]
    let messages: [MessageRecord]
    let files: [FileRecord]
    let memory: [AIMemoryRecord]
}
