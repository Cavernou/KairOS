import SwiftUI

struct SaveConsoleOverlay: View {
    @EnvironmentObject private var appState: AppState
    @State private var passcode = ""

    var body: some View {
        VStack {
            Spacer(minLength: 40)

            PanelView(title: "SAVE BLACKBOX") {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Projector-mode quick save. Writes a real encrypted .kairbox backup into the app Documents/Blackbox directory.")
                        .font(KairOSTypography.mono)

                    SecureField("ENTER BLACKBOX PASSCODE", text: $passcode)
                        .textFieldStyle(.roundedBorder)
                        .font(KairOSTypography.mono)

                    HStack(spacing: 10) {
                        Button("SAVE") {
                            appState.exportBlackbox(passcode: passcode)
                            if !appState.blackboxStatus.hasPrefix("EXPORT FAILED") && !appState.blackboxStatus.hasPrefix("SAVE REQUIRES") {
                                appState.isShowingSaveConsole = false
                            }
                        }
                        .buttonStyle(HeaderButtonChrome())

                        Button("CANCEL") {
                            appState.soundManager.play(.archivistFileWindowClose)
                            appState.isShowingSaveConsole = false
                        }
                        .buttonStyle(HeaderButtonChrome())
                    }

                    Text(appState.blackboxStatus)
                        .font(KairOSTypography.header)

                    if let lastBackupLocation = appState.lastBackupLocation {
                        Text(lastBackupLocation)
                            .font(KairOSTypography.mono)
                    }

                    Text("SOUND BANK READY: \(KairOSSoundCatalog.futureSlots.joined(separator: " | "))")
                        .font(KairOSTypography.mono)
                }
            }
            .frame(maxWidth: 760)

            Spacer()
        }
    }
}
