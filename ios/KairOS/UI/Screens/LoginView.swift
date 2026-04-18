import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @State private var kairNumber: String = "K"
    @State private var passcode: String = ""
    @State private var errorText: String?
    @State private var isLoggingIn = false

    var body: some View {
        PanelView(title: "LOGIN") {
            VStack(alignment: .leading, spacing: 20) {
                // K-NUMBER input
                VStack(alignment: .leading, spacing: 8) {
                    Text("K-NUMBER")
                        .font(KairOSTypography.mono)
                    TextField("K-XXXX", text: $kairNumber)
                        .font(KairOSTypography.mono)
                        .textFieldStyle(IndustrialTextFieldStyle())
                        .onChange(of: kairNumber) { newValue in
                            // Ensure K prefix
                            var formatted = newValue
                            if !formatted.hasPrefix("K") {
                                formatted = "K" + formatted
                            }
                            if formatted.isEmpty {
                                formatted = "K"
                            }
                            // Auto-format: K-XXXX (4 digits after K)
                            let digits = formatted.filter { $0.isNumber }
                            let chunk = String(digits.prefix(4))
                            var result = "K"
                            if !chunk.isEmpty { result += "-" + chunk }
                            kairNumber = result
                        }
                }

                // PASSCODE input
                VStack(alignment: .leading, spacing: 8) {
                    Text("PASSCODE")
                        .font(KairOSTypography.mono)
                    SecureField("ENTER PASSCODE", text: $passcode)
                        .font(KairOSTypography.mono)
                        .textFieldStyle(IndustrialTextFieldStyle())
                }

                // Error message
                if let errorText {
                    Text(errorText)
                        .font(KairOSTypography.mono)
                        .foregroundStyle(KairOSColors.alert)
                }

                // Login button
                Button(isLoggingIn ? "LOGGING IN..." : "LOGIN") {
                    Task { await login() }
                }
                .buttonStyle(HeaderButtonChrome())
                .disabled(isLoggingIn)
                .frame(maxWidth: .infinity)

                // Help button
                Button("HELP") {
                    // Show help
                }
                .font(KairOSTypography.mono)
                .foregroundStyle(KairOSColors.chrome)
            }
            .font(KairOSTypography.mono)
        }
    }

    private func login() async {
        isLoggingIn = true
        defer { isLoggingIn = false }

        // Validate inputs
        guard !kairNumber.isEmpty else {
            errorText = "K-NUMBER is required"
            return
        }

        guard kairNumber.hasPrefix("K") else {
            errorText = "K-NUMBER must start with K"
            return
        }

        let pattern = "^K-\\d{4}$"
        guard kairNumber.range(of: pattern, options: .regularExpression) != nil else {
            errorText = "K-NUMBER must be in format K-XXXX (4 digits)"
            return
        }

        guard !passcode.isEmpty else {
            errorText = "PASSCODE is required"
            return
        }

        errorText = nil

        // TODO: Implement actual login logic with IdentityManager
        // For now, just simulate success
        appState.soundManager.play(.accessGranted)
    }
}

struct IndustrialTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(KairOSColors.background)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(KairOSColors.chrome, lineWidth: 1)
            )
    }
}
