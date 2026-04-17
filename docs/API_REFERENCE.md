# KairOS API Reference

## Home Node gRPC API

### Service: KairOSNode

#### ActivateDevice
Activates a new device on the network.

**Request:**
```protobuf
message ActivateRequest {
  string device_id = 1;
  string kair_number = 2;
  bytes public_key = 3;
  string admin_code = 4;
}
```

**Response:**
```protobuf
message ActivateResponse {
  bool activated = 1;
  string activation_state = 2;
  string device_id = 3;
  string kair_number = 4;
  ErrorStatus error = 5;
}
```

#### SendMessage
Sends a message packet through the node.

**Request:**
```protobuf
message MessagePacket {
  string id = 1;
  string type = 2;
  string sender_kair = 3;
  string receiver_kair = 4;
  int64 timestamp = 5;
  bytes encrypted_payload = 6;
  repeated string node_route = 7;
  bool has_attachments = 8;
}
```

**Response:**
```protobuf
message SendResult {
  string id = 1;
  string status = 2;
  int32 retry_count = 3;
  ErrorStatus error = 4;
}
```

#### SendFileChunk
Streams file chunks between devices.

**Request Stream:**
```protobuf
message FileChunk {
  string transfer_id = 1;
  string sender_kair = 2;
  string receiver_kair = 3;
  int32 chunk_index = 4;
  int32 total_chunks = 5;
  bytes encrypted_payload = 6;
  string checksum = 7;
  int64 timestamp = 8;
}
```

**Response:**
```protobuf
message TransferStatus {
  string transfer_id = 1;
  string status = 2;
  int32 received_chunks = 3;
  ErrorStatus error = 4;
}
```

#### FetchQueue
Retrieves queued messages for a device.

**Request:**
```protobuf
message FetchRequest {
  string receiver_kair = 1;
  string device_id = 2;
}
```

**Response Stream:**
```protobuf
message QueuedItem {
  string id = 1;
  string type = 2;
  bytes encrypted_payload = 3;
  int64 timestamp = 4;
  int32 retry_count = 5;
}
```

#### GetContacts
Retrieves the contact list.

**Request:**
```protobuf
message Empty {}
```

**Response:**
```protobuf
message ContactList {
  repeated Contact contacts = 1;
  ErrorStatus error = 2;
}

message Contact {
  string knumber = 1;
  string display_name = 2;
  string real_phone = 3;
  string notes = 4;
  string trust_status = 5;
  int64 last_interaction = 6;
  string avatar_ascii = 7;
}
```

#### UpdateTrustScore
Updates trust score for a contact.

**Request:**
```protobuf
message TrustUpdate {
  string kair_number = 1;
  double delta = 2;
  string reason = 3;
}
```

**Response:**
```protobuf
message Empty {}
```

#### StoreAIMemory
Stores AI memory entries.

**Request:**
```protobuf
message MemoryEntry {
  string id = 1;
  string memory_type = 2;
  string target_id = 3;
  string content = 4;
  double importance = 5;
  int64 created_at = 6;
}
```

**Response:**
```protobuf
message Empty {}
```

#### RetrieveAIMemory
Retrieves AI memory entries.

**Request:**
```protobuf
message MemoryQuery {
  string key = 1;
}
```

**Response:**
```protobuf
message MemoryEntry {
  string id = 1;
  string memory_type = 2;
  string target_id = 3;
  string content = 4;
  double importance = 5;
  int64 created_at = 6;
}
```

## iOS App SDK

### KairOSAPI Protocol

```swift
protocol KairOSAPI {
    func readFile(named: String) -> Data?
    func writeFile(named: String, data: Data) throws
    func listFiles() -> [String]
    func sendMessage(to kairNumber: String, text: String, attachments: [URL]?) async throws
    func queryALICE(prompt: String) async -> String
    func publish(event: String, payload: [String: Any])
    func subscribe(to event: String, handler: @escaping ([String: Any]) -> Void)
}
```

### App Runtime Events

#### Global Events
- `message.received` - New message received
- `contact.added` - Contact added to list
- `node.status.changed` - Node connectivity changed
- `call.incoming` - Incoming voice call
- `file.received` - File transfer completed

#### Event Payload Format
```swift
// message.received
{
    "id": "uuid",
    "sender": "K-1234-5678",
    "text": "Hello",
    "timestamp": 1700000000000,
    "hasAttachments": false
}

// node.status.changed
{
    "isReachable": true,
    "tailnet": "kairos.ts.net",
    "lastSync": 1700000000000
}
```

### App Manifest Format

```json
{
  "id": "com.kairos.notes",
  "name": "Notes",
  "version": "1.0.0",
  "entry_type": "panel",
  "permissions": ["files", "local_storage", "ai", "events"],
  "commands": [
    {
      "name": "create_note",
      "description": "Create a new note",
      "ai_access": true,
      "parameters": { "title": "string", "content": "string" }
    }
  ],
  "ai_summary": "Manages text notes with tagging."
}
```

### Available Permissions

- `files` - Access to app-local file storage
- `local_storage` - Persistent data storage
- `ai` - Query ALICE AI assistant
- `events` - Subscribe to global events
- `network` - Network access (via node)
- `contacts` - Access to contact list

### ALICE AI Tools

#### Built-in System Tools
- `send_message` - Send message (requires confirmation)
- `list_files` - List files (no confirmation)
- `read_file` - Read file (no confirmation)
- `search_contacts` - Search contacts (no confirmation)
- `start_call` - Start voice call (requires confirmation)
- `delete_file` - Delete file (requires confirmation)

#### Tool Call Format
```swift
// ALICE generates tool calls
{
    "tool": "send_message",
    "parameters": {
        "to": "K-1234-5678",
        "text": "Hello from ALICE"
    }
}
```

## Mock HTTP API (Development)

For development without full gRPC setup, the node provides a mock HTTP API:

### Endpoints

#### GET /mock/v1/status
```json
{
    "isReachable": true,
    "tailnet": "kairos.ts.net",
    "lastSync": 1700000000000
}
```

#### POST /mock/v1/activate
```json
{
    "activated": true,
    "activationState": "active",
    "deviceId": "uuid",
    "kairNumber": "K-1234-5678",
    "debugAdminCode": "0420"
}
```

#### POST /mock/v1/messages
```json
{
    "id": "uuid",
    "status": "sent",
    "retryCount": 0
}
```

#### GET /mock/v1/contacts
```json
{
    "contacts": [
        {
            "knumber": "K-1000-0001",
            "displayName": "Home Node",
            "realPhone": null,
            "notes": "Primary trusted node",
            "trustStatus": "trusted",
            "lastInteraction": 1700000000000,
            "avatarAscii": "[NODE]"
        }
    ]
}
```

#### GET /mock/v1/queue
```json
[
    {
        "id": "uuid",
        "type": "message",
        "encryptedPayload": "base64data",
        "timestamp": 1700000000000,
        "retryCount": 0
    }
]
```

## Error Handling

### gRPC Status Codes
- `OK (0)` - Success
- `INVALID_ARGUMENT (3)` - Invalid request parameters
- `UNAUTHENTICATED (16)` - Authentication failed
- `PERMISSION_DENIED (7)` - Insufficient permissions
- `NOT_FOUND (5)` - Resource not found
- `UNAVAILABLE (14)` - Service unavailable
- `DEADLINE_EXCEEDED (4)` - Request timeout

### iOS Error Types
```swift
enum KairOSError: Error {
    case nodeUnreachable
    case invalidKairNumber
    case activationFailed
    case encryptionFailed
    case fileNotFound
    case permissionDenied
    case networkError(Error)
}
```

## Security Considerations

### Encryption Standards
- AES-256-GCM for message encryption
- Curve25519 for key exchange
- PBKDF2 with 100,000 iterations for Blackbox encryption
- TLS 1.3 for node communication

### Authentication Flow
1. Device generates Curve25519 key pair
2. Device sends activation request with admin code
3. Node validates admin code and registers device
4. All subsequent communication uses device's public key

### Trust Scoring
- Initial score: 0.5 for new contacts
- Successful interaction: +0.1
- Failed delivery: -0.05
- User report: -0.2
- Score range: 0.0 (blocked) to 1.0 (fully trusted)
