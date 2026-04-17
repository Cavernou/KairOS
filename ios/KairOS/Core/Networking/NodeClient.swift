import Foundation

struct Contact {
    let id: String
    let displayName: String
    let trustStatus: String
    let avatarASCII: String?
}

struct MemoryEntry {
    let key: String
    let value: String
    let timestamp: Int64
}

class NodeClient {
    struct Endpoint: Equatable {
        static let hostDefaultsKey = "kairos.node.host"
        static let portDefaultsKey = "kairos.node.port"
        static let useTailscaleKey = "kairos.node.use_tailscale"

        let host: String
        let port: Int
        let useTailscale: Bool

        static func stored() -> Endpoint {
            let defaults = UserDefaults.standard
            let useTailscale = defaults.bool(forKey: useTailscaleKey)
            
            if useTailscale {
                let host = defaults.string(forKey: hostDefaultsKey) ?? "100.109.117.124"
                let port = defaults.object(forKey: portDefaultsKey) as? Int ?? 8081
                return Endpoint(host: host, port: port, useTailscale: true)
            }
            
            let host = defaults.string(forKey: hostDefaultsKey) ?? "127.0.0.1"
            let port = defaults.object(forKey: portDefaultsKey) as? Int ?? 8080
            return Endpoint(host: host, port: port, useTailscale: false)
        }

        static func persist(host: String, port: Int, useTailscale: Bool = false) {
            let defaults = UserDefaults.standard
            defaults.set(host, forKey: hostDefaultsKey)
            defaults.set(port, forKey: portDefaultsKey)
            defaults.set(useTailscale, forKey: useTailscaleKey)
        }
    }

    struct ActivationResult {
        let state: String
        let debugAdminCode: String?
    }

    private var endpoint: Endpoint
    private var isReachable = false
    
    init(endpoint: Endpoint = .stored()) {
        self.endpoint = endpoint
    }
    
    func updateEndpoint(host: String, port: Int, useTailscale: Bool = true) async {
        endpoint = Endpoint(host: host, port: port, useTailscale: useTailscale)
        Endpoint.persist(host: host, port: port, useTailscale: useTailscale)
    }
    
    private func buildURL(path: String) -> URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = endpoint.host
        components.port = endpoint.port
        components.path = path
        return components.url!
    }
    
    func activateDevice(deviceID: String, kairNumber: String, publicKey: String, adminCode: String, avatarData: Data?) async throws -> ActivationResult {
        let url = buildURL(path: "/mock/v1/activate")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "device_id": deviceID,
            "kair_number": kairNumber,
            "public_key": publicKey,
            "admin_code": adminCode
        ]
        
        if let avatarData = avatarData {
            body["avatar_data"] = avatarData.base64EncodedString()
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ActivationResponse.self, from: data)
        
        return ActivationResult(state: response.state, debugAdminCode: response.debugAdminCode)
    }
    
    func send(packet: MessagePacket) async throws -> String {
        let url = buildURL(path: "/mock/v1/send")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "id": packet.id,
            "type": packet.type,
            "sender_kair": packet.senderKair,
            "receiver_kair": packet.receiverKair,
            "timestamp": packet.timestamp,
            "encrypted_payload": packet.encryptedPayload.base64EncodedString(),
            "node_route": packet.nodeRoute,
            "has_attachments": packet.hasAttachments
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SendResponse.self, from: data)
        
        return response.status
    }
    
    func fetchContacts() async throws -> [Contact] {
        let url = buildURL(path: "/mock/v1/contacts")
        
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ContactsResponse.self, from: data)
        
        return response.contacts.map { contact in
            Contact(
                id: contact.kairNumber,
                displayName: contact.displayName,
                trustStatus: contact.trustStatus,
                avatarASCII: contact.avatarASCII
            )
        }
    }
    
    func storeAIMemory(entry: MemoryEntry) async throws {
        let url = buildURL(path: "/mock/v1/memory")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "key": entry.key,
            "value": entry.value,
            "timestamp": entry.timestamp
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        _ = try await URLSession.shared.data(for: request)
    }
    
    func syncMemory(_ entry: MemoryEntry) async throws {
        let url = buildURL(path: "/mock/v1/memory")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "key": entry.key,
            "value": entry.value,
            "timestamp": entry.timestamp
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        _ = try await URLSession.shared.data(for: request)
    }

    func fetchQueue() async throws -> [MessagePacket] {
        let url = buildURL(path: "/mock/v1/queue")
        
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(QueueResponse.self, from: data)
        
        return response.items.map { item in
            MessagePacket(
                id: item.id,
                type: item.type,
                senderKair: item.senderKair,
                receiverKair: item.receiverKair,
                timestamp: item.timestamp,
                encryptedPayload: Data(base64Encoded: item.encryptedPayload) ?? Data(),
                nodeRoute: item.nodeRoute,
                hasAttachments: item.hasAttachments
            )
        }
    }

    func currentStatus() async -> NodeStatus {
        return NodeStatus(isReachable: isReachable, tailnet: endpoint.useTailscale ? "kairos.ts.net" : "local", lastSync: isReachable ? .now : nil)
    }

    func setReachable(_ value: Bool) async {
        isReachable = value
    }
    
    // MARK: - Response Types
    
    struct ActivationResponse: Codable {
        let state: String
        let debugAdminCode: String?
    }
    
    struct SendResponse: Codable {
        let status: String
    }
    
    struct ContactResponse: Codable {
        let kairNumber: String
        let displayName: String
        let trustStatus: String
        let avatarASCII: String?
    }
    
    struct ContactsResponse: Codable {
        let contacts: [ContactResponse]
    }
    
    struct QueueItemResponse: Codable {
        let id: String
        let type: String
        let senderKair: String
        let receiverKair: String
        let timestamp: Int64
        let encryptedPayload: String
        let nodeRoute: [String]
        let hasAttachments: Bool
    }
    
    struct QueueResponse: Codable {
        let items: [QueueItemResponse]
    }
}
