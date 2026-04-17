import SwiftUI

struct NodesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var discoveredNodes: [DiscoveredNode] = []
    @State private var isScanning = false

    var body: some View {
        PanelView(title: "NODES") {
            VStack(alignment: .leading, spacing: 12) {
                Text("NODE DISCOVERY")
                    .font(KairOSTypography.header)
                
                Button("SCAN FOR NODES") {
                    appState.soundManager.playClick()
                    Task { await scanForNodes() }
                }
                .buttonStyle(HeaderButtonChrome())
                .disabled(isScanning)
                
                if isScanning {
                    Text("SCANNING...")
                        .font(KairOSTypography.mono)
                }
                
                if !discoveredNodes.isEmpty {
                    Text("DISCOVERED NODES:")
                        .font(KairOSTypography.mono)
                    
                    ForEach(discoveredNodes) { node in
                        HStack {
                            Text(node.name)
                                .font(KairOSTypography.mono)
                            Text(node.ipAddress)
                                .font(KairOSTypography.mono)
                            Button("CONNECT") {
                                appState.soundManager.playClick()
                                Task { await connectToNode(node) }
                            }
                            .buttonStyle(HeaderButtonChrome())
                        }
                    }
                }
                
                Divider()
                
                Text("CURRENT CONNECTION:")
                    .font(KairOSTypography.mono)
                Text(appState.nodeStatus.isReachable ? "PRIMARY NODE ONLINE" : "PRIMARY NODE OFFLINE")
                    .font(KairOSTypography.header)
                Text("Tailnet: \(appState.nodeStatus.tailnet)")
                    .font(KairOSTypography.mono)
                Text("Last Sync: \(appState.nodeStatus.lastSync?.formatted() ?? "never")")
                    .font(KairOSTypography.mono)

                HStack(spacing: 10) {
                    Button("SYNC CONTACTS") {
                        appState.soundManager.playClick()
                        Task { await appState.refreshContacts() }
                    }
                    .buttonStyle(HeaderButtonChrome())

                    Button(appState.nodeStatus.isReachable ? "DISCONNECT" : "CONNECT") {
                        appState.soundManager.playClick()
                        Task { await appState.setNodeReachable(!appState.nodeStatus.isReachable) }
                    }
                    .buttonStyle(HeaderButtonChrome())
                }
            }
        }
    }
    
    private func scanForNodes() async {
        isScanning = true
        // Scan local network for KairOS nodes
        // This would use mDNS or network scanning
        // For now, simulate discovery
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        discoveredNodes = [
            DiscoveredNode(name: "Mac Studio", ipAddress: "100.109.117.124", port: 8081),
            DiscoveredNode(name: "Test Node", ipAddress: "192.168.1.100", port: 8081)
        ]
        
        isScanning = false
    }
    
    private func connectToNode(_ node: DiscoveredNode) async {
        await appState.nodeClient.updateEndpoint(host: node.ipAddress, port: node.port, useTailscale: false)
        await appState.refreshNodeStatus()
    }
}

struct DiscoveredNode: Identifiable {
    let id = UUID()
    let name: String
    let ipAddress: String
    let port: Int
}
