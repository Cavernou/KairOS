import Foundation
import Network

@MainActor
final class TailscaleManager: ObservableObject {
    @Published var isConnected = false
    @Published var tailnet = "kairos.ts.net"
    @Published var status: VPNStatus = .disconnected
    
    private let nodeTailscaleIP = "100.109.117.124"
    private let nodeHTTPPort = 8080
    
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
        checkTailscaleConnection()
    }
    
    func checkTailscaleConnection() {
        // Check if we can reach the node's Tailscale IP
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
        
        // Check if Tailscale network is available
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
        
        // We cannot disconnect Tailscale ourselves
        // User must disconnect via the official Tailscale app
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        isConnected = false
        status = .disconnected
    }
    
    func getStatus() async -> VPNStatus {
        return status
    }
    
    func getPeerStatus() async -> [TailscalePeer] {
        // Return known node if connected
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
