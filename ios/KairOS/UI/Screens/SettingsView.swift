import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        PanelView(title: "SETTINGS") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Identity, passcode, Tailnet endpoint, and tool confirmations live here.")
                    .font(KairOSTypography.mono)
                Text("ACTIVE IDENTITY: \(appState.identityManager.identity?.kairNumber ?? "UNSET")")
                    .font(KairOSTypography.header)
                HStack(spacing: 10) {
                    TextField("NODE HOST", text: $appState.nodeHost)
                        .textFieldStyle(.roundedBorder)
                        .onTapGesture {
                            appState.soundManager.playSubtleClick()
                        }
                    TextField("PORT", text: $appState.nodePort)
                        .textFieldStyle(.roundedBorder)
                        .onTapGesture {
                            appState.soundManager.playSubtleClick()
                        }
                    Button("APPLY LINK") {
                        appState.soundManager.playClick()
                        Task { await appState.applyNodeEndpoint() }
                    }
                    .buttonStyle(HeaderButtonChrome())
                }
                .font(KairOSTypography.mono)
                Text("TEST NODE: http://\(appState.nodeHost):\(appState.nodePort)/mock/v1")
                    .font(KairOSTypography.mono)
                Text("FONT PACK: REF IMAGE FONTS LOADED")
                    .font(KairOSTypography.mono)
                Text("SYSTEM SOUNDS: \(KairOSSoundCatalog.allBundled.count) LOADED")
                    .font(KairOSTypography.mono)
                Text("FUTURE SOUND SLOTS: \(KairOSSoundCatalog.futureSlots.joined(separator: ", "))")
                    .font(KairOSTypography.mono)
            }
        }
    }
}
