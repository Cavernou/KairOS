import Foundation
import Network

// Conditional import for TailscaleKit - will only compile if SDK is available
#if canImport(TailscaleKit)
import TailscaleKit
#endif

@MainActor
final class TailscaleManager: ObservableObject {
    @Published var isConnected = false
    @Published var tailnet = "kairos.ts.net"
    @Published var status: VPNStatus = .disconnected
    
    private let nodeTailscaleIP = "100.109.117.124"
    private let nodeHTTPPort = 8080 // gRPC port
    
    #if canImport(TailscaleKit)
    private var tailscaleClient: TailscaleClient?
    #endif
    
    enum VPNStatus {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case disconnecting
        case error(String)
        
        var description: String {
            switch self {
            case .disconnected: return "DISCONNECTED"
            case .connecting: return "CONNECTING"
            case .connected: return "CONNECTED"
            case .reconnecting: return "RECONNECTING"
            case .disconnecting: return "DISCONNECTING"
            case .error(let message): return "ERROR: \(message)"
            }
        }
    }
    
    init() {
        setupTailscaleClient()
        checkTailscaleConnection()
    }
    
    private func setupTailscaleClient() {
        #if canImport(TailscaleKit)
        // Try to initialize TailscaleKit client if available
        do {
            tailscaleClient = try TailscaleClient()
            print("✅ TailscaleKit client initialized")
        } catch {
            print("⚠️ TailscaleKit not available, using fallback: \(error.localizedDescription)")
            tailscaleClient = nil
        }
        #else
        print("ℹ️ TailscaleKit not available, using connectivity check fallback")
        #endif
    }
    
    func checkTailscaleConnection() {
        #if canImport(TailscaleKit)
        if let client = tailscaleClient {
            // Use TailscaleKit to check connection status
            Task {
                do {
                    let peers = try await client.getPeers()
                    let connected = peers.contains { $0.addresses.contains(nodeTailscaleIP) }
                    
                    DispatchQueue.main.async {
                        self.isConnected = connected
                        self.status = connected ? .connected : .disconnected
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.isConnected = false
                        self.status = .error(error.localizedDescription)
                    }
                }
            }
            return
        }
        #endif
        
        // Fallback: Check if we can reach the node's Tailscale IP
        // This assumes the official Tailscale app is installed and connected
        let connection = NWConnection(host: NWEndpoint.Host(nodeTailscaleIP), port: NWEndpoint.Port(rawValue: UInt16(nodeHTTPPort))!, using: .tcp)
        
        connection.stateUpdateHandler = { [weak self] (state: NWConnection.State) in
            switch state {
            case .ready:
                DispatchQueue.main.async {
                    self?.isConnected = true
                    self?.status = .connected
                }
            case .failed(let error):
                DispatchQueue.main.async {
                    self?.isConnected = false
                    self?.status = .error(error.localizedDescription)
                }
            case .waiting(let error):
                DispatchQueue.main.async {
                    self?.isConnected = false
                    self?.status = .connecting
                }
            default:
                break
            }
        }
        
        connection.start(queue: DispatchQueue.global(qos: .background))
    }
    
    func connect() async {
        status = .connecting
        
        #if canImport(TailscaleKit)
        if let client = tailscaleClient {
            // Use TailscaleKit to start VPN (if entitlements allow)
            do {
                try await client.startVPN()
                status = .connected
                isConnected = true
            } catch {
                status = .error("Failed to start VPN: \(error.localizedDescription)")
                isConnected = false
            }
            return
        }
        #endif
        
        // Fallback: Check if Tailscale network is available
        // This relies on the official Tailscale app being installed and connected
        // We cannot establish VPN connection ourselves due to iOS restrictions
        
        checkTailscaleConnection()
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        if isConnected {
            status = .connected
        } else {
            status = .error("Tailscale not available - ensure Tailscale app is installed and connected")
        }
    }
    
    func disconnect() async {
        status = .disconnecting
        
        #if canImport(TailscaleKit)
        if let client = tailscaleClient {
            // Use TailscaleKit to stop VPN (if entitlements allow)
            do {
                try await client.stopVPN()
                status = .disconnected
                isConnected = false
            } catch {
                status = .error("Failed to stop VPN: \(error.localizedDescription)")
            }
            return
        }
        #endif
        
        // Fallback: We cannot disconnect Tailscale ourselves
        // User must disconnect via the official Tailscale app
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        isConnected = false
        status = .disconnected
    }
    
    func getStatus() async -> VPNStatus {
        return status
    }
    
    func getPeerStatus() async -> [TailscalePeer] {
        #if canImport(TailscaleKit)
        if let client = tailscaleClient {
            do {
                let peers = try await client.getPeers()
                return peers.map { peer in
                    TailscalePeer(
                        id: peer.id,
                        name: peer.name,
                        addresses: peer.addresses,
                        online: peer.online,
                        lastSeen: peer.lastSeen
                    )
                }
            } catch {
                print("Failed to get peer status: \(error.localizedDescription)")
            }
        }
        #endif
        
        // Fallback: Return known node if connected
        if isConnected {
            return [
                TailscalePeer(
                    id: "nWC364uA8621CNTRL",
                    name: "Home Node",
                    addresses: [nodeTailscaleIP],
                    online: true,
                    lastSeen: Date()
                )
            ]
        }
        return []
    }
    
    func isTailscaleAvailable() async -> Bool {
        #if canImport(TailscaleKit)
        if let client = tailscaleClient {
            return await client.isConnected()
        }
        #endif
        return isConnected
    }
    
    func getNodeEndpoint() -> String {
        return "\(nodeTailscaleIP):\(nodeHTTPPort)"
    }
}

struct TailscalePeer {
    let id: String
    let name: String
    let addresses: [String]
    let online: Bool
    let lastSeen: Date
}

#if canImport(TailscaleKit)
// TailscaleKit wrapper (placeholder - actual SDK would have its own types)
class TailscaleClient {
    func getPeers() async throws -> [TailscaleSDKPeer] {
        // Placeholder - actual SDK implementation
        return []
    }
    
    func startVPN() async throws {
        // Placeholder - requires NetworkExtension entitlements
        throw NSError(domain: "TailscaleClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "VPN control requires NetworkExtension entitlements"])
    }
    
    func stopVPN() async throws {
        // Placeholder - requires NetworkExtension entitlements
        throw NSError(domain: "TailscaleClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "VPN control requires NetworkExtension entitlements"])
    }
    
    func isConnected() async -> Bool {
        return false
    }
}

struct TailscaleSDKPeer {
    let id: String
    let name: String
    let addresses: [String]
    let online: Bool
    let lastSeen: Date
}
#endif
