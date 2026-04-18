import SwiftUI

struct CallingView: View {
    @State private var callingNumber: String = "K"
    @State private var isCalling = false
    @StateObject private var callManager = VoiceCallManager()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        PanelView(title: "CALLING") {
            VStack(alignment: .leading, spacing: 20) {
                // Calling input field
                VStack(alignment: .leading, spacing: 8) {
                    Text("DESTINATION K-NUMBER")
                        .font(KairOSTypography.mono)
                    TextField("K-XXXX-XXXX-XXXX-XXXX", text: $callingNumber)
                        .font(KairOSTypography.mono)
                        .textFieldStyle(IndustrialTextFieldStyle())
                        .onChange(of: callingNumber) { newValue in
                            // Ensure K prefix
                            if !newValue.hasPrefix("K") {
                                callingNumber = "K" + newValue
                            }
                            // Remove K if user tries to delete it
                            if newValue.isEmpty {
                                callingNumber = "K"
                            }
                        }
                }

                // Call status
                if let currentCall = callManager.currentCall {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CALL STATUS")
                            .font(KairOSTypography.mono)
                        Text(currentCall.state.description)
                            .font(KairOSTypography.header)
                        if currentCall.state == .connected {
                            Text(currentCall.formattedDuration)
                                .font(KairOSTypography.lcd)
                        }
                    }
                }

                // Dial pad
                dialPadGrid

                // Call control buttons
                callControlButtons

                // Call history
                if !callManager.callHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CALL HISTORY")
                            .font(KairOSTypography.mono)
                        ForEach(callManager.callHistory.prefix(5)) { record in
                            HStack {
                                Text(record.remoteKairNumber)
                                    .font(KairOSTypography.mono)
                                Spacer()
                                Text(record.formattedDate)
                                    .font(KairOSTypography.mono)
                                Text(record.formattedDuration)
                                    .font(KairOSTypography.mono)
                            }
                        }
                    }
                }
            }
        }
    }

    private var dialPadGrid: some View {
        VStack(spacing: 8) {
            ForEach(0..<3) { row in
                HStack(spacing: 8) {
                    ForEach(0..<3) { col in
                        let digit = row * 3 + col + 1
                        dialButton(digit: digit)
                    }
                }
            }
            HStack(spacing: 8) {
                dialButton(digit: 0)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dialButton(digit: Int) -> some View {
        Button("\(digit)") {
            appState.soundManager.playClick()
        }
        .font(KairOSTypography.header)
        .frame(width: 60, height: 60)
        .background(KairOSColors.background)
        .foregroundColor(KairOSColors.chrome)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(KairOSColors.chrome, lineWidth: 2)
        )
        .onLongPressGesture(minimumDuration: 0, pressing: { isPressing in
            if isPressing {
                callManager.playDialTone(digit: digit)
            } else {
                callManager.stopDialTone()
            }
        }, perform: {})
    }

    private var callControlButtons: some View {
        HStack(spacing: 16) {
            Button("CALL") {
                Task {
                    appState.soundManager.playClick()
                    do {
                        try await callManager.startCall(to: callingNumber)
                        isCalling = true
                    } catch {
                        appState.soundManager.play(.disappointingFailure)
                    }
                }
            }
            .font(KairOSTypography.header)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(KairOSColors.chrome)
            .foregroundColor(KairOSColors.background)
            .cornerRadius(8)
            .disabled(isCalling || callingNumber.count < 3)

            Button("END") {
                Task {
                    appState.soundManager.playClick()
                    do {
                        try await callManager.endCall(hangupType: .normal)
                        isCalling = false
                    } catch {
                        appState.soundManager.play(.disappointingFailure)
                    }
                }
            }
            .font(KairOSTypography.header)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(KairOSColors.background)
            .foregroundColor(KairOSColors.chrome)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(KairOSColors.chrome, lineWidth: 2)
            )
            .disabled(!isCalling)
        }
    }
}

struct IndustrialTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(KairOSColors.background)
            .foregroundColor(KairOSColors.chrome)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(KairOSColors.chrome, lineWidth: 2)
            )
    }
}
