import SwiftUI

struct HelpView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PanelView(title: "HELP") {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Registration Guide
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REGISTRATION")
                            .font(KairOSTypography.header)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("1. Enter your K-NUMBER (format: K-XXXX)")
                                .font(KairOSTypography.mono)
                            Text("   - The K prefix and dash are automatically added")
                                .font(KairOSTypography.mono)
                                .foregroundStyle(KairOSColors.chrome.opacity(0.7))
                            Text("   - Example: Type 1234 to get K-1234")
                                .font(KairOSTypography.mono)
                                .foregroundStyle(KairOSColors.chrome.opacity(0.7))
                            
                            Text("2. Enter your DISPLAY NAME")
                                .font(KairOSTypography.mono)
                            Text("   - 2-32 characters")
                                .font(KairOSTypography.mono)
                                .foregroundStyle(KairOSColors.chrome.opacity(0.7))
                            
                            Text("3. Create a PASSCODE")
                                .font(KairOSTypography.mono)
                            Text("   - Keep it secret and memorable")
                                .font(KairOSTypography.mono)
                                .foregroundStyle(KairOSColors.chrome.opacity(0.7))
                            Text("   - Minimum 4 characters recommended")
                                .font(KairOSTypography.mono)
                                .foregroundStyle(KairOSColors.chrome.opacity(0.7))
                            
                            Text("4. Get ADMIN CODE from Node Control Center")
                                .font(KairOSTypography.mono)
                            Text("   - Open http://localhost:8081 in a browser")
                                .font(KairOSTypography.mono)
                                .foregroundStyle(KairOSColors.chrome.opacity(0.7))
                            Text("   - Click 'GENERATE CODE' button")
                                .font(KairOSTypography.mono)
                                .foregroundStyle(KairOSColors.chrome.opacity(0.7))
                            Text("   - Code expires in 5 minutes")
                                .font(KairOSTypography.mono)
                                .foregroundStyle(KairOSColors.chrome.opacity(0.7))
                            
                            Text("5. Upload optional AVATAR image")
                                .font(KairOSTypography.mono)
                            Text("   - Max size: 5MB")
                                .font(KairOSTypography.mono)
                                .foregroundStyle(KairOSColors.chrome.opacity(0.7))
                            Text("   - Max dimensions: 2048x2048")
                                .font(KairOSTypography.mono)
                                .foregroundStyle(KairOSColors.chrome.opacity(0.7))
                            
                            Text("6. Click ACTIVATE to complete registration")
                                .font(KairOSTypography.mono)
                        }
                    }
                    .padding(12)
                    .background(KairOSColors.background.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(KairOSColors.chrome, lineWidth: 1)
                    )
                    
                    // Calling Guide
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CALLING")
                            .font(KairOSTypography.header)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Enter destination K-NUMBER")
                                .font(KairOSTypography.mono)
                            Text("• Use dial pad to enter digits")
                                .font(KairOSTypography.mono)
                            Text("• Press and hold dial buttons to play tones")
                                .font(KairOSTypography.mono)
                            Text("• Click CALL to initiate call")
                                .font(KairOSTypography.mono)
                            Text("• Click END to hang up")
                                .font(KairOSTypography.mono)
                        }
                    }
                    .padding(12)
                    .background(KairOSColors.background.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(KairOSColors.chrome, lineWidth: 1)
                    )
                    
                    // Troubleshooting
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TROUBLESHOOTING")
                            .font(KairOSTypography.header)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Activation failed? Check admin code and try again")
                                .font(KairOSTypography.mono)
                            Text("• Can't connect to node? Ensure node is running on port 8080")
                                .font(KairOSTypography.mono)
                            Text("• Avatar upload failed? Check file size and dimensions")
                                .font(KairOSTypography.mono)
                        }
                    }
                    .padding(12)
                    .background(KairOSColors.background.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(KairOSColors.chrome, lineWidth: 1)
                    )
                }
                .font(KairOSTypography.mono)
                .foregroundStyle(KairOSColors.chrome)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button("CLOSE") {
                appState.soundManager.playClick()
                dismiss()
            }
            .buttonStyle(HeaderButtonChrome())
            .padding()
        }
    }
}
