import SwiftUI

struct BlackboxView: View {
    @EnvironmentObject private var appState: AppState
    @State private var passcode = ""

    var body: some View {
        PanelView(title: "BLACKBOX") {
            VStack(alignment: .leading, spacing: 12) {
                SecureField("BLACKBOX PASSCODE", text: $passcode)
                    .textFieldStyle(.roundedBorder)
                    .font(KairOSTypography.mono)
                    .onTapGesture {
                        appState.soundManager.playSubtleClick()
                    }
                HStack(spacing: 10) {
                    Button("EXPORT SNAPSHOT") {
                        appState.soundManager.play(.oldDataUnpackProcessing)
                        appState.exportBlackbox(passcode: passcode)
                    }
                    .buttonStyle(HeaderButtonChrome())

                    Button("SAVE CONSOLE") {
                        appState.soundManager.play(.areYouSure)
                        appState.isShowingSaveConsole = true
                    }
                    .buttonStyle(HeaderButtonChrome())
                }
                Text(appState.blackboxStatus)
                    .font(KairOSTypography.mono)
                if let lastBackupLocation = appState.lastBackupLocation {
                    Text(lastBackupLocation)
                        .font(KairOSTypography.mono)
                        .foregroundStyle(KairOSColors.muted)
                }
                Text("Export encrypted .kairbox snapshots or restore local cache state.")
                    .font(KairOSTypography.mono)
                if let latestSnapshot = appState.cache.snapshots.first {
                    Divider()
                        .overlay(KairOSColors.chrome)
                    Text("LATEST SNAPSHOT")
                        .font(KairOSTypography.header)
                    Text(latestSnapshot.filename)
                        .font(KairOSTypography.mono)
                    Text("SIZE \(latestSnapshot.size) BYTES")
                        .font(KairOSTypography.mono)
                }
                Text("AUDIO BANK \(KairOSSoundCatalog.allBundled.count) SYSTEM SOUNDS LOADED")
                    .font(KairOSTypography.mono)
            }
        }
    }
}
