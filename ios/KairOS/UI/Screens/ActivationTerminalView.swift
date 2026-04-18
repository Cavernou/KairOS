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
    @State private var avatarError: String?

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
                // Validate image size (max 5MB)
                let imageData = newImage.jpegData(compressionQuality: 0.8)
                if let data = imageData, data.count > 5 * 1024 * 1024 {
                    avatarError = "Image too large. Maximum size is 5MB."
                    avatarImage = nil
                    avatarData = nil
                    return
                }

                // Validate image dimensions (max 2048x2048)
                let size = newImage.size
                if size.width > 2048 || size.height > 2048 {
                    avatarError = "Image too large. Maximum dimensions are 2048x2048."
                    avatarImage = nil
                    avatarData = nil
                    return
                }

                avatarData = imageData
                avatarError = nil
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
                        .onChange(of: viewModel.kairNumber) { newValue in
                            // Ensure K prefix
                            var formatted = newValue
                            if !formatted.hasPrefix("K") {
                                formatted = "K" + formatted
                            }
                            // Remove K if user tries to delete it
                            if formatted.isEmpty {
                                formatted = "K"
                            }
                            // Auto-format: K-XXXX (4 digits after K)
                            let digits = formatted.filter { $0.isNumber }
                            let prefix = String(digits.prefix(1))
                            let chunk = String(digits.dropFirst().prefix(4))
                            var result = "K"
                            if !chunk.isEmpty { result += "-" + chunk }
                            viewModel.kairNumber = result
                        }
                        .onTapGesture {
                            appState.soundManager.playSubtleClick()
                        }
                }

                HStack {
                    TextField("DISPLAY NAME", text: $viewModel.displayName)
                        .textFieldStyle(IndustrialTextFieldStyle())
                        .onTapGesture {
                            appState.soundManager.playSubtleClick()
                        }
                }

                HStack {
                    SecureField("PASSCODE", text: $passcode)
                        .textFieldStyle(IndustrialTextFieldStyle())
                        .onTapGesture {
                            appState.soundManager.playSubtleClick()
                        }
                }

                HStack {
                    TextField("ADMIN CODE", text: $viewModel.adminCode)
                        .textFieldStyle(IndustrialTextFieldStyle())
                        .onTapGesture {
                            appState.soundManager.playSubtleClick()
                        }
                }

                // Avatar upload
                VStack(alignment: .leading, spacing: 8) {
                    Text("AVATAR (OPTIONAL)")
                        .font(KairOSTypography.mono)
                    Text("Upload an image to represent your device")
                        .font(KairOSTypography.mono)
                        .foregroundStyle(KairOSColors.chrome.opacity(0.7))
                    Text("Max size: 5MB, Max dimensions: 2048x2048")
                        .font(KairOSTypography.mono)
                        .foregroundStyle(KairOSColors.chrome.opacity(0.5))

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

                    if let avatarError = avatarError {
                        Text(avatarError)
                            .font(KairOSTypography.mono)
                            .foregroundStyle(KairOSColors.alert)
                    }
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
                Button(viewModel.isActivating ? "ACTIVATING..." : "ACTIVATE") {
                    Task { await activate() }
                }
                .buttonStyle(HeaderButtonChrome())
                .disabled(viewModel.isActivating)

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
            errorText = viewModel.errorMessage
            appState.soundManager.play(viewModel.activationState == "active" ? .accessGranted : .reminder)
            await appState.refreshNodeStatus()
        } catch {
            errorText = viewModel.errorMessage ?? error.localizedDescription
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
