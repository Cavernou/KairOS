import SwiftUI
import UIKit

struct ActivationTerminalView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ActivationViewModel
    @State private var passcode = ""
    @State private var errorText: String?
    @State private var showingImagePicker = false
    @State private var avatarImage: UIImage?
    @State private var avatarData: Data?

    init(identityManager: IdentityManager, nodeClient: NodeClient) {
        _viewModel = StateObject(wrappedValue: ActivationViewModel(identityManager: identityManager, nodeClient: nodeClient))
    }

    var body: some View {
        GeometryReader { proxy in
            let mode = LayoutMode(width: proxy.size.width, height: proxy.size.height)

            ZStack {
                KairOSColors.background.ignoresSafeArea()

                Group {
                    if mode.isLandscape {
                        HStack(alignment: .top, spacing: 24) {
                            heroBlock
                                .frame(maxWidth: .infinity, alignment: .leading)
                            formBlock
                                .frame(maxWidth: 420, alignment: .leading)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 18) {
                            heroBlock
                            formBlock
                        }
                    }
                }
                .padding(mode.isLandscape ? 32 : 24)
                .foregroundStyle(KairOSColors.chrome)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $avatarImage)
        }
        .onChange(of: avatarImage) { _, newImage in
            if let newImage = newImage {
                avatarData = newImage.jpegData(compressionQuality: 0.8)
            }
        }
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("ACTIVATE TERMINAL")
                .font(KairOSTypography.hero)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var formBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    TextField("K-NUMBER", text: $viewModel.kairNumber)
                        .textFieldStyle(IndustrialTextFieldStyle())
                        .onTapGesture {
                            appState.soundManager.playSubtleClick()
                        }
                    Button("?") {
                        appState.soundManager.playSubtleClick()
                        // Show tooltip for K-NUMBER
                    }
                    .font(KairOSTypography.mono)
                    .foregroundStyle(KairOSColors.chrome)
                    .help("Your unique KairOS identifier. Format: K-XXXX-XXXX")
                }

                HStack {
                    SecureField("PASSCODE", text: $passcode)
                        .textFieldStyle(IndustrialTextFieldStyle())
                        .onTapGesture {
                            appState.soundManager.playSubtleClick()
                        }
                    Button("?") {
                        appState.soundManager.playSubtleClick()
                        // Show tooltip for PASSCODE
                    }
                    .font(KairOSTypography.mono)
                    .foregroundStyle(KairOSColors.chrome)
                    .help("Your personal passcode. Keep it secret.")
                }

                HStack {
                    TextField("ADMIN CODE", text: $viewModel.adminCode)
                        .textFieldStyle(IndustrialTextFieldStyle())
                        .onTapGesture {
                            appState.soundManager.playSubtleClick()
                        }
                    Button("?") {
                        appState.soundManager.playSubtleClick()
                        // Show tooltip for ADMIN CODE
                    }
                    .font(KairOSTypography.mono)
                    .foregroundStyle(KairOSColors.chrome)
                    .help("Admin code from your KairOS Node control center. Click 'GENERATE CODE' in the control center to get one.")
                }
                
                // Avatar upload
                VStack(alignment: .leading, spacing: 8) {
                    Text("AVATAR")
                        .font(KairOSTypography.mono)
                    
                    Button(action: {
                        appState.soundManager.playClick()
                        showingImagePicker = true
                    }) {
                        ZStack {
                            if let avatarImage = avatarImage {
                                Image(uiImage: avatarImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            } else {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(KairOSColors.chrome, lineWidth: 1)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text("UPLOAD")
                                            .font(KairOSTypography.mono)
                                            .foregroundStyle(KairOSColors.chrome)
                                    )
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if let debugAdminCode = viewModel.debugAdminCode, viewModel.activationState == "pending_admin_code" {
                    Text("TEST NODE CODE \(debugAdminCode)")
                        .font(KairOSTypography.mono)
                        .foregroundStyle(KairOSColors.led)
                }
            }
            .font(KairOSTypography.mono)
        }
        .panelChrome()
        .overlay(alignment: .bottomLeading) {
            HStack(spacing: 12) {
                Button("ACTIVATE") {
                    Task { await activate() }
                }
                .buttonStyle(HeaderButtonChrome())

                Text(viewModel.activationState.replacingOccurrences(of: "_", with: " ").uppercased())
                    .font(KairOSTypography.mono)

                if let errorText {
                    Text(errorText)
                        .font(KairOSTypography.mono)
                        .foregroundStyle(KairOSColors.alert)
                }
            }
            .padding(.top, 182)
        }
        .padding(.bottom, 54)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func activate() async {
        appState.soundManager.play(.keyType1)
        
        do {
            try await viewModel.activate(avatarData: avatarData)
            errorText = nil
            appState.soundManager.play(viewModel.activationState == "active" ? .accessGranted : .reminder)
            await appState.refreshNodeStatus()
        } catch {
            errorText = error.localizedDescription
            appState.soundManager.play(.warningUI)
        }
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
