import SwiftUI

struct MessagesView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var cache: LocalCache
    @State private var receiver = "K-2000-0002"
    @State private var composeText = ""

    var body: some View {
        PanelView(title: "MESSAGES") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    TextField("RECIPIENT", text: $receiver)
                        .textFieldStyle(.roundedBorder)
                        .onTapGesture {
                            appState.soundManager.playSubtleClick()
                        }
                    TextField("MESSAGE PAYLOAD", text: $composeText)
                        .textFieldStyle(.roundedBorder)
                        .onTapGesture {
                            appState.soundManager.playSubtleClick()
                        }
                    Button("SEND") {
                        appState.soundManager.playClick()
                        guard !composeText.isEmpty else { return }
                        Task {
                            await appState.sendMessage(to: receiver, text: composeText)
                            composeText = ""
                        }
                    }
                    .buttonStyle(HeaderButtonChrome())
                }
                .font(KairOSTypography.mono)

                ForEach(cache.messages) { message in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(message.senderKNumber) -> \(message.receiverKNumber)")
                                .font(KairOSTypography.header)
                            Spacer()
                            Text(message.status.uppercased())
                                .font(KairOSTypography.mono)
                                .foregroundStyle(message.status == "failed" ? KairOSColors.alert : KairOSColors.chrome)
                        }
                        Text(message.text ?? "[ENCRYPTED PAYLOAD]")
                            .font(KairOSTypography.mono)
                        Text(message.timestamp.formatted(date: .omitted, time: .standard))
                            .font(KairOSTypography.mono)
                            .foregroundStyle(KairOSColors.muted)
                    }
                    Divider()
                        .overlay(KairOSColors.chrome)
                }
            }
        }
    }
}
