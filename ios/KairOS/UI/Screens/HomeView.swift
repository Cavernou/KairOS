import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var nodeHost = NodeClient.Endpoint.stored().host
    @Published var nodePort = String(NodeClient.Endpoint.stored().port)
    @Published var selectedTab: AppTab = .messages
    @Published var nodeStatus = NodeStatus(isReachable: false, tailnet: "kairos.ts.net", lastSync: nil)
    @Published var blackboxStatus = "NO SNAPSHOT"
    @Published var lastBackupLocation: String?
    @Published var isShowingSaveConsole = false

    let cache = LocalCache()
    let identityManager = IdentityManager()
    let nodeClient = NodeClient()
    let soundManager = SoundManager.shared

    init() {
        cache.seedPreviewData()
        soundManager.playAmbient()
        Task { await refreshNodeStatus() }
    }

    func refreshNodeStatus() async {
        nodeStatus = await nodeClient.currentStatus()
    }

    func refreshContacts() async {
        if let contacts = try? await nodeClient.fetchContacts() {
            let contactRecords = contacts.map { contact in
                ContactRecord(
                    id: contact.id,
                    displayName: contact.displayName,
                    realPhone: nil,
                    notes: nil,
                    trustStatus: contact.trustStatus,
                    lastInteraction: nil,
                    avatarASCII: contact.avatarASCII
                )
            }
            cache.replaceAll(
                from: CacheSnapshot(
                    contacts: contactRecords,
                    messages: cache.messages,
                    files: cache.files,
                    memory: cache.memory
                )
            )
            nodeStatus.lastSync = .now
        }
    }

    func setNodeReachable(_ value: Bool) async {
        await nodeClient.setReachable(value)
        await refreshNodeStatus()
    }

    func applyNodeEndpoint() async {
        guard let port = Int(nodePort), !nodeHost.isEmpty else { return }
        await nodeClient.updateEndpoint(host: nodeHost, port: port)
        await refreshNodeStatus()
    }

    func sendMessage(to receiver: String, text: String) async {
        guard let identity = identityManager.identity else { return }
        let packet = MessagePacket(
            id: UUID().uuidString,
            type: "message",
            senderKair: identity.kairNumber,
            receiverKair: receiver,
            timestamp: Int64(Date.now.timeIntervalSince1970 * 1000),
            encryptedPayload: Data(text.utf8),
            nodeRoute: ["home-node"],
            hasAttachments: false
        )

        let status = (try? await nodeClient.send(packet: packet)) ?? "failed"
        soundManager.play(status == "failed" ? .warningUI : .userSendMessage)
        cache.append(
            message: MessageRecord(
                id: packet.id,
                senderKNumber: packet.senderKair,
                receiverKNumber: packet.receiverKair,
                text: text,
                timestamp: .now,
                status: status,
                hasAttachments: false,
                encryptedPayload: packet.encryptedPayload
            )
        )
        await refreshNodeStatus()
    }

    func exportBlackbox(passcode: String) {
        guard let identity = identityManager.identity else { return }
        guard !passcode.isEmpty else {
            blackboxStatus = "SAVE REQUIRES PASSCODE"
            soundManager.play(.warningUI)
            return
        }
        do {
            soundManager.play(.oldDataUnpackProcessing)
            let artifact = try BlackboxExporter.exportToDocuments(cache: cache.snapshot(), identity: identity, passcode: passcode)
            cache.record(
                snapshot: BlackboxSnapshotRecord(
                    id: UUID().uuidString,
                    filename: artifact.filename,
                    createdAt: .now,
                    size: artifact.size,
                    checksum: artifact.checksum,
                    location: artifact.url.path
                )
            )
            lastBackupLocation = artifact.url.path
            blackboxStatus = "SAVED \(artifact.filename.uppercased())"
            soundManager.play(.tadaSuccess)
        } catch {
            blackboxStatus = "EXPORT FAILED"
            soundManager.play(.disappointingFailure)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GeometryReader { proxy in
            let mode = LayoutMode(width: proxy.size.width, height: proxy.size.height)

            Group {
                if appState.identityManager.identity?.status != "active" {
                    ActivationTerminalView(identityManager: appState.identityManager, nodeClient: appState.nodeClient)
                } else {
                    shell(mode: mode)
                }
            }
        }
    }

    private func shell(mode: LayoutMode) -> some View {
        ZStack {
            KairOSColors.background.ignoresSafeArea()
            TelemetryGrid()
                .padding(.horizontal, 40)
                .padding(.vertical, 88)
            ScanlineOverlay()

            VStack(alignment: .leading, spacing: 18) {
                topHeader(mode: mode)
                TelemetryRule()
                Group {
                    if mode.isLandscape {
                        HStack(alignment: .top, spacing: 20) {
                            HatchMarks(flipped: false)
                                .padding(.top, 44)
                            currentPanel
                            HatchMarks(flipped: true)
                                .padding(.top, 44)
                        }
                    } else {
                        VStack(spacing: 14) {
                            currentPanel
                            HStack {
                                HatchMarks(flipped: false)
                                Spacer()
                                HatchMarks(flipped: true)
                            }
                        }
                    }
                }
                footer(mode: mode)
            }
            .padding(24)
            .foregroundStyle(KairOSColors.chrome)

            if appState.isShowingSaveConsole {
                SaveConsoleOverlay()
                    .environmentObject(appState)
                    .padding(mode.isLandscape ? 64 : 24)
            }
        }
    }

    private func topHeader(mode: LayoutMode) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            TabBarView(selection: $appState.selectedTab, mode: mode)
            HStack {
                Text("UNREGISTERED LOCATION")
                    .font(KairOSTypography.header)
                Spacer()
                HStack(spacing: 10) {
                    Button("SAVE") {
                        appState.soundManager.play(.areYouSure)
                        appState.isShowingSaveConsole = true
                    }
                    .buttonStyle(HeaderButtonChrome())

                    LEDIndicator(isOn: appState.nodeStatus.isReachable)
                    Text(appState.nodeStatus.isReachable ? "NODE ONLINE" : "NODE OFFLINE")
                        .font(KairOSTypography.mono)
                }
            }
        }
    }

    private func footer(mode: LayoutMode) -> some View {
        VStack(spacing: 16) {
            TelemetryRule()
            Group {
                if mode.isLandscape {
                    HStack(alignment: .center) {
                        brandBlock
                        Spacer()
                        statusBlock
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        brandBlock
                        HStack {
                            Spacer()
                            statusBlock
                        }
                    }
                }
            }
        }
    }

    private var brandBlock: some View {
        HStack(spacing: 8) {
            Text("+")
                .font(KairOSTypography.header)
            Text("KairOS")
                .font(KairOSTypography.title)
            BarcodeStrip()
                .frame(width: 110)
        }
    }

    private var statusBlock: some View {
        HStack(spacing: 14) {
            Text(appState.blackboxStatus)
                .font(KairOSTypography.mono)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(appState.identityManager.identity?.kairNumber ?? "K-UNSET")
                .font(KairOSTypography.mono)
            Text(Date.now.formatted(date: .omitted, time: .shortened))
                .font(KairOSTypography.lcd)
            Text("+")
                .font(KairOSTypography.header)
        }
    }

    @ViewBuilder
    private var currentPanel: some View {
        switch appState.selectedTab {
        case .messages:
            MessagesView(cache: appState.cache)
        case .files:
            FilesView()
        case .contacts:
            ContactsView(cache: appState.cache)
        case .nodes:
            NodesView()
        case .apps:
            AppsView()
        case .settings:
            SettingsView()
        case .blackbox:
            BlackboxView()
        }
    }
}
